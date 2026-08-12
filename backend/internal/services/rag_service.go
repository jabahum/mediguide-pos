package services

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"mediguide/internal/aiworkergrpc"
	"mediguide/internal/aiworkerpb"
	"mediguide/internal/config"
	"mediguide/internal/models"
	"mediguide/internal/security"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"gorm.io/gorm"
)

type RAGService struct {
	DB     *gorm.DB
	Search SearchService
	Cfg    config.Config
}

type AskRequest struct {
	Question    string `json:"question"`
	Language    string `json:"language"`
	Country     string `json:"country"`
	ProgramArea string `json:"program_area"`
	SessionID   string `json:"session_id"`
}

type workerAskRequest struct {
	Question       string              `json:"question"`
	Language       string              `json:"language"`
	Country        string              `json:"country,omitempty"`
	ProgramArea    string              `json:"program_area"`
	HistorySummary string              `json:"history_summary,omitempty"`
	RecentMessages []workerChatMessage `json:"recent_messages,omitempty"`
}

type workerChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type Citation struct {
	ChunkID       string `json:"chunk_id"`
	GuidelineID   string `json:"guideline_id,omitempty"`
	SectionID     string `json:"section_id,omitempty"`
	BlockID       string `json:"block_id,omitempty"`
	Title         string `json:"title"`
	SourceName    string `json:"source_name"`
	SourceVersion string `json:"source_version"`
	PageStart     *int   `json:"page_start"`
	PageEnd       *int   `json:"page_end"`
}
type AskResponse struct {
	Answer    string     `json:"answer"`
	Citations []Citation `json:"citations"`
	SessionID string     `json:"session_id"`
}

const assistantUserEmail = "assistant@mediguide.local"

var (
	ErrInvalidRAGQuestion = errors.New("question must be between 2 and 12000 characters")
	ErrInvalidRAGSession  = errors.New("invalid RAG session id")
	ErrRAGSessionNotFound = errors.New("RAG session not found")
)

func (s RAGService) Ask(userID *uuid.UUID, req AskRequest) (*AskResponse, error) {
	req.Question = strings.TrimSpace(req.Question)
	if utf8.RuneCountInString(req.Question) < 2 || utf8.RuneCountInString(req.Question) > 12000 {
		return nil, ErrInvalidRAGQuestion
	}
	session, err := s.getOrCreateSession(userID, req)
	if err != nil {
		return nil, err
	}

	workerReq, err := s.buildWorkerAskRequest(session.ID, req)
	if err != nil {
		return nil, err
	}

	res, err := s.askWithConfiguredProvider(workerReq)
	if err != nil {
		return nil, err
	}

	res.SessionID = session.ID.String()
	s.enrichCitations(res.Citations)
	cjson, _ := json.Marshal(res.Citations)
	if err := s.DB.Create(&models.ChatMessage{
		SessionID:     session.ID,
		Role:          "user",
		Content:       req.Question,
		CitationsJSON: "[]",
	}).Error; err != nil {
		log.Warn().Err(err).Str("session_id", session.ID.String()).Msg("failed to persist user chat message")
	}
	if err := s.DB.Create(&models.ChatMessage{
		SessionID:     session.ID,
		Role:          "assistant",
		Content:       res.Answer,
		CitationsJSON: string(cjson),
	}).Error; err != nil {
		log.Warn().Err(err).Str("session_id", session.ID.String()).Msg("failed to persist assistant chat message")
	}
	if userID != nil && *userID != uuid.Nil {
		if err := s.mirrorToLegacyConversation(*userID, req.Question, res.Answer); err != nil {
			log.Warn().Err(err).Str("user_id", userID.String()).Msg("failed to mirror RAG exchange to legacy conversations")
		}
	}
	return res, nil
}

// enrichCitations attaches stable domain identifiers to worker citations. The
// worker protocol intentionally remains retrieval-focused; navigation metadata
// is resolved from the authoritative PostgreSQL chunk rows before responding.
func (s RAGService) enrichCitations(citations []Citation) {
	if len(citations) == 0 {
		return
	}
	ids := make([]uuid.UUID, 0, len(citations))
	for _, citation := range citations {
		if id, err := uuid.Parse(citation.ChunkID); err == nil {
			ids = append(ids, id)
		}
	}
	if len(ids) == 0 {
		return
	}
	var chunks []models.GuidelineChunk
	if err := s.DB.Select("id", "document_id", "section_id", "block_id").Where("id IN ?", ids).Find(&chunks).Error; err != nil {
		log.Warn().Err(err).Msg("failed to enrich RAG citation navigation")
		return
	}
	byID := make(map[string]models.GuidelineChunk, len(chunks))
	for _, chunk := range chunks {
		byID[chunk.ID.String()] = chunk
	}
	for index := range citations {
		chunk, ok := byID[citations[index].ChunkID]
		if !ok {
			continue
		}
		citations[index].GuidelineID = chunk.DocumentID.String()
		if chunk.SectionID != nil {
			citations[index].SectionID = chunk.SectionID.String()
		}
		if chunk.BlockID != nil {
			citations[index].BlockID = chunk.BlockID.String()
		}
	}
}

func (s RAGService) askWithConfiguredProvider(req workerAskRequest) (*AskResponse, error) {
	provider := strings.ToLower(strings.TrimSpace(s.Cfg.AIRAGProvider))
	if provider == "worker" || provider == "ai-worker" {
		if res, err := s.askWorker(req); err == nil {
			return res, nil
		} else {
			log.Warn().Err(err).Msg("ai-worker RAG failed, falling back to local search")
		}
	}
	return s.askLocal(req)
}

func (s RAGService) askWorker(req workerAskRequest) (*AskResponse, error) {
	timeout := time.Duration(s.workerTimeoutSeconds()) * time.Second

	dialCtx, dialCancel := context.WithTimeout(context.Background(), timeout)
	defer dialCancel()

	client, err := aiworkergrpc.NewClient(dialCtx, s.Cfg.AIWorkerGRPCAddr, s.Cfg.AIWorkerSecret)
	if err != nil {
		return nil, err
	}
	defer client.Close()

	callCtx, callCancel := context.WithTimeout(context.Background(), timeout)
	defer callCancel()

	workerResp, err := client.AskRAG(
		callCtx,
		&aiworkerpb.AskRAGRequest{
			Question:       req.Question,
			Language:       req.Language,
			Country:        req.Country,
			ProgramArea:    req.ProgramArea,
			HistorySummary: req.HistorySummary,
			RecentMessages: toGRPCChatMessages(req.RecentMessages),
		},
	)
	if err != nil {
		return nil, err
	}

	citations := make([]Citation, 0, len(workerResp.Citations))
	for _, c := range workerResp.Citations {
		citations = append(citations, Citation{
			ChunkID:       c.ChunkId,
			Title:         c.Title,
			SourceName:    c.SourceName,
			SourceVersion: c.SourceVersion,
			PageStart:     protoPage(c.PageStart),
			PageEnd:       protoPage(c.PageEnd),
		})
	}
	return &AskResponse{Answer: workerResp.Answer, Citations: citations}, nil
}

func (s RAGService) workerTimeoutSeconds() int {
	if s.Cfg.AIWorkerTimeoutSecs > 0 {
		return s.Cfg.AIWorkerTimeoutSecs
	}
	return 120
}

func protoPage(value int32) *int {
	if value <= 0 {
		return nil
	}
	page := int(value)
	return &page
}

func toGRPCChatMessages(messages []workerChatMessage) []*aiworkerpb.ChatMessage {
	if len(messages) == 0 {
		return nil
	}
	out := make([]*aiworkerpb.ChatMessage, 0, len(messages))
	for _, message := range messages {
		out = append(out, &aiworkerpb.ChatMessage{
			Role:    message.Role,
			Content: message.Content,
		})
	}
	return out
}

func (s RAGService) askLocal(req workerAskRequest) (*AskResponse, error) {
	results, err := s.Search.Search(s.buildLocalSearchQuestion(req), req.ProgramArea, 5)
	if err != nil {
		return nil, err
	}
	citations := []Citation{}
	parts := []string{}
	for _, r := range results {
		citations = append(citations, Citation{ChunkID: r.ID, Title: r.Title, SourceName: r.SourceName, SourceVersion: r.SourceVersion, PageStart: r.PageStart, PageEnd: r.PageEnd})
		parts = append(parts, "- "+r.Snippet)
	}
	answer := "I found the following approved guideline content that may answer the question. Please review the cited source sections before clinical use:\n\n" + strings.Join(parts, "\n")
	if len(results) == 0 {
		answer = "I could not find an answer in the approved guideline content. Please consult the current national guideline or refer to a senior clinician."
	}
	return &AskResponse{Answer: answer, Citations: citations}, nil
}

func (s RAGService) getOrCreateSession(userID *uuid.UUID, req AskRequest) (*models.ChatSession, error) {
	var session models.ChatSession
	if req.SessionID != "" {
		sid, err := uuid.Parse(req.SessionID)
		if err != nil {
			return nil, ErrInvalidRAGSession
		}
		query := s.DB.Where("id = ?", sid)
		if userID != nil && *userID != uuid.Nil {
			query = query.Where("user_id = ?", *userID)
		} else {
			query = query.Where("user_id IS NULL")
		}
		if err := query.First(&session).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return nil, ErrRAGSessionNotFound
			}
			return nil, err
		}
		return &session, nil
	}
	session = models.ChatSession{
		UserID: s.resolveChatSessionUserID(userID),
		Title:  truncate(req.Question, 80),
	}
	if err := s.DB.Create(&session).Error; err != nil {
		return nil, err
	}
	return &session, nil
}

func (s RAGService) buildWorkerAskRequest(sessionID uuid.UUID, req AskRequest) (workerAskRequest, error) {
	historySummary, recentMessages, err := s.loadConversationContext(sessionID)
	if err != nil {
		return workerAskRequest{}, err
	}

	return workerAskRequest{
		Question:       req.Question,
		Language:       req.Language,
		Country:        req.Country,
		ProgramArea:    req.ProgramArea,
		HistorySummary: historySummary,
		RecentMessages: recentMessages,
	}, nil
}

func (s RAGService) loadConversationContext(sessionID uuid.UUID) (string, []workerChatMessage, error) {
	var messages []models.ChatMessage
	if err := s.DB.
		Where("session_id = ?", sessionID).
		Order("created_at desc").
		Limit(8).
		Find(&messages).Error; err != nil {
		return "", nil, err
	}
	if len(messages) == 0 {
		return "", nil, nil
	}

	for left, right := 0, len(messages)-1; left < right; left, right = left+1, right-1 {
		messages[left], messages[right] = messages[right], messages[left]
	}

	summaryMessages := messages
	if len(summaryMessages) > 4 {
		summaryMessages = summaryMessages[:len(summaryMessages)-4]
	} else {
		summaryMessages = nil
	}

	recentMessages := messages
	if len(recentMessages) > 4 {
		recentMessages = recentMessages[len(recentMessages)-4:]
	}

	recent := make([]workerChatMessage, 0, len(recentMessages))
	for _, message := range recentMessages {
		content := strings.TrimSpace(message.Content)
		if content == "" {
			continue
		}
		recent = append(recent, workerChatMessage{
			Role:    message.Role,
			Content: truncate(content, 320),
		})
	}

	return s.summarizeMessages(summaryMessages), recent, nil
}

func (s RAGService) summarizeMessages(messages []models.ChatMessage) string {
	if len(messages) == 0 {
		return ""
	}

	parts := make([]string, 0, len(messages))
	for _, message := range messages {
		content := strings.TrimSpace(message.Content)
		if content == "" {
			continue
		}

		role := "Assistant"
		if strings.EqualFold(message.Role, "user") {
			role = "User"
		}
		parts = append(parts, fmt.Sprintf("%s: %s", role, truncate(content, 220)))
	}

	return truncate(strings.Join(parts, " | "), 1200)
}

func (s RAGService) buildLocalSearchQuestion(req workerAskRequest) string {
	question := strings.TrimSpace(req.Question)
	if question == "" {
		return question
	}
	if len(req.RecentMessages) == 0 || looksStandalone(question) {
		return question
	}

	for index := len(req.RecentMessages) - 1; index >= 0; index-- {
		message := req.RecentMessages[index]
		if strings.EqualFold(message.Role, "user") && strings.TrimSpace(message.Content) != "" {
			return question + " Related prior question: " + strings.TrimSpace(message.Content)
		}
	}

	if strings.TrimSpace(req.HistorySummary) != "" {
		return question + " Related prior context: " + strings.TrimSpace(req.HistorySummary)
	}
	return question
}

func (s RAGService) resolveChatSessionUserID(userID *uuid.UUID) *uuid.UUID {
	if userID == nil || *userID == uuid.Nil {
		return nil
	}

	var count int64
	if err := s.DB.Model(&models.User{}).Where("id = ?", *userID).Count(&count).Error; err != nil {
		log.Warn().Err(err).Str("user_id", userID.String()).Msg("failed to validate RAG chat user; creating anonymous session")
		return nil
	}
	if count == 0 {
		log.Warn().Str("user_id", userID.String()).Msg("RAG chat user not found; creating anonymous session")
		return nil
	}

	return userID
}

func (s RAGService) mirrorToLegacyConversation(userID uuid.UUID, question, answer string) error {
	assistantID, err := s.lookupAssistantUserID()
	if err != nil {
		return err
	}

	conversationID, err := s.findOrCreateLegacyConversation(userID, assistantID)
	if err != nil {
		return err
	}

	now := time.Now().UTC()
	userReadBy := map[string]any{
		userID.String(): now.Format(time.RFC3339),
	}
	assistantReadBy := map[string]any{
		userID.String():      now.Format(time.RFC3339),
		assistantID.String(): now.Format(time.RFC3339),
	}

	userMessage := map[string]any{
		"id":               uuid.New(),
		"conversation_id":  conversationID,
		"sender_user_id":   userID,
		"content":          strings.TrimSpace(question),
		"message_type":     "text",
		"read_by_json":     userReadBy,
		"reactions_json":   map[string]any{},
		"attachments_json": []any{},
		"is_edited":        false,
		"created_at":       now,
		"updated_at":       now,
	}
	if err := s.DB.Table("messages").Create(&userMessage).Error; err != nil {
		return err
	}

	assistantMessage := map[string]any{
		"id":               uuid.New(),
		"conversation_id":  conversationID,
		"sender_user_id":   assistantID,
		"content":          strings.TrimSpace(answer),
		"message_type":     "text",
		"read_by_json":     assistantReadBy,
		"reactions_json":   map[string]any{},
		"attachments_json": []any{},
		"is_edited":        false,
		"created_at":       now,
		"updated_at":       now,
	}
	if err := s.DB.Table("messages").Create(&assistantMessage).Error; err != nil {
		return err
	}

	return s.DB.Table("conversations").
		Where("id = ?", conversationID).
		Updates(map[string]any{
			"last_activity": now.Format(time.RFC3339),
			"updated_at":    now,
		}).Error
}

func (s RAGService) lookupAssistantUserID() (uuid.UUID, error) {
	var assistant models.User
	if err := s.DB.Select("id").Where("email = ?", assistantUserEmail).First(&assistant).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			hash, hashErr := security.HashPassword("Assistant123!")
			if hashErr != nil {
				return uuid.Nil, hashErr
			}
			assistant = models.User{
				Name:         "MediGuide AI",
				Email:        assistantUserEmail,
				Phone:        "+256700000003",
				PasswordHash: hash,
				IsActive:     true,
				Verified:     true,
				Status:       "active",
			}
			if createErr := s.DB.Create(&assistant).Error; createErr != nil {
				return uuid.Nil, createErr
			}
			return assistant.ID, nil
		}
		return uuid.Nil, err
	}
	return assistant.ID, nil
}

func (s RAGService) findOrCreateLegacyConversation(userID, assistantID uuid.UUID) (uuid.UUID, error) {
	var row struct {
		ID uuid.UUID `gorm:"column:id"`
	}
	err := s.DB.Table("conversations").
		Select("id").
		Where(
			"(participant1_user_id = ? AND participant2_user_id = ?) OR (participant1_user_id = ? AND participant2_user_id = ?)",
			userID,
			assistantID,
			assistantID,
			userID,
		).
		Where("deleted_at IS NULL").
		Take(&row).Error
	if err == nil {
		return row.ID, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return uuid.Nil, err
	}

	createRow := map[string]any{
		"id":                   uuid.New(),
		"participant1_user_id": userID,
		"participant2_user_id": assistantID,
		"last_activity":        time.Now().UTC().Format(time.RFC3339),
		"created_at":           time.Now().UTC(),
		"updated_at":           time.Now().UTC(),
	}
	if err := s.DB.Table("conversations").Create(&createRow).Error; err != nil {
		return uuid.Nil, err
	}
	return createRow["id"].(uuid.UUID), nil
}

// truncate shortens s to at most n Unicode code points (runes), not bytes,
// so it is safe for multilingual content (Luganda, Swahili, etc.).
func truncate(s string, n int) string {
	if utf8.RuneCountInString(s) <= n {
		return s
	}
	runes := []rune(s)
	return string(runes[:n])
}

func looksStandalone(question string) bool {
	normalized := strings.ToLower(strings.TrimSpace(question))
	if normalized == "" {
		return true
	}

	followUps := []string{
		"what about",
		"how about",
		"and what about",
		"what if",
		"does that",
		"is that",
		"is it",
		"can it",
		"can they",
		"can we",
		"what are they",
		"what are those",
		"why is that",
		"when should that",
		"when should it",
	}
	for _, prefix := range followUps {
		if strings.HasPrefix(normalized, prefix) {
			return false
		}
	}

	pronouns := []string{
		" it ",
		" that ",
		" those ",
		" they ",
		" them ",
		" this ",
		" these ",
		" the other ",
	}
	padded := " " + normalized + " "
	for _, pronoun := range pronouns {
		if strings.Contains(padded, pronoun) {
			return false
		}
	}
	return true
}
