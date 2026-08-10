package services

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

var ErrInvalidGuidelineBlockContent = errors.New("invalid guideline block content")

func ValidateGuidelineBlockContent(blockType models.GuidelineBlockType, raw json.RawMessage) error {
	if len(bytes.TrimSpace(raw)) == 0 {
		return ErrInvalidGuidelineBlockContent
	}

	var err error
	switch blockType {
	case models.GuidelineBlockHeading:
		var payload models.GuidelineHeadingBlockPayload
		err = decodeGuidelineBlock(raw, &payload)
		if err == nil && (blank(payload.Text) || payload.Level < 1 || payload.Level > 6) {
			err = ErrInvalidGuidelineBlockContent
		}
		if err == nil {
			err = requireGuidelineBlockType(payload.Type, blockType)
		}
	case models.GuidelineBlockParagraph, models.GuidelineBlockUnknown:
		var payload models.GuidelineTextBlockPayload
		err = decodeGuidelineBlock(raw, &payload)
		if err == nil && blank(payload.Text) {
			err = ErrInvalidGuidelineBlockContent
		}
		if err == nil {
			err = requireGuidelineBlockType(payload.Type, blockType)
		}
	case models.GuidelineBlockOrderedList, models.GuidelineBlockUnorderedList:
		var payload models.GuidelineListBlockPayload
		err = decodeGuidelineBlock(raw, &payload)
		if err == nil && (len(payload.Items) == 0 || containsBlank(payload.Items)) {
			err = ErrInvalidGuidelineBlockContent
		}
		if err == nil {
			err = requireGuidelineBlockType(payload.Type, blockType)
		}
	case models.GuidelineBlockTable:
		var payload models.GuidelineTableBlockPayload
		err = decodeGuidelineBlock(raw, &payload)
		if err == nil {
			err = validateGuidelineTable(payload)
		}
		if err == nil {
			err = requireGuidelineBlockType(payload.Type, blockType)
		}
	case models.GuidelineBlockFigure:
		var payload models.GuidelineFigureBlockPayload
		err = decodeGuidelineBlock(raw, &payload)
		if err == nil && (payload.AssetID == uuid.Nil || blank(payload.AlternativeText)) {
			err = ErrInvalidGuidelineBlockContent
		}
		if err == nil {
			err = requireGuidelineBlockType(payload.Type, blockType)
		}
	case models.GuidelineBlockRecommendation, models.GuidelineBlockWarning, models.GuidelineBlockKeyPoint:
		var payload models.GuidelineCalloutBlockPayload
		err = decodeGuidelineBlock(raw, &payload)
		if err == nil && (blank(payload.Content) || !validGuidelineSeverity(payload.Severity)) {
			err = ErrInvalidGuidelineBlockContent
		}
		if err == nil {
			err = requireGuidelineBlockType(payload.Type, blockType)
		}
	case models.GuidelineBlockAlgorithm:
		var payload models.GuidelineAlgorithmBlockPayload
		err = decodeGuidelineBlock(raw, &payload)
		if err == nil {
			err = validateGuidelineAlgorithm(payload)
		}
		if err == nil {
			err = requireGuidelineBlockType(payload.Type, blockType)
		}
	case models.GuidelineBlockReference:
		var payload models.GuidelineReferenceBlockPayload
		err = decodeGuidelineBlock(raw, &payload)
		if err == nil && blank(payload.Citation) {
			err = ErrInvalidGuidelineBlockContent
		}
		if err == nil {
			err = requireGuidelineBlockType(payload.Type, blockType)
		}
	case models.GuidelineBlockPageBreak:
		var payload models.GuidelinePageBreakBlockPayload
		err = decodeGuidelineBlock(raw, &payload)
		if err == nil && payload.Page < 1 {
			err = ErrInvalidGuidelineBlockContent
		}
		if err == nil {
			err = requireGuidelineBlockType(payload.Type, blockType)
		}
	default:
		err = ErrInvalidGuidelineBlockContent
	}

	if err != nil {
		return fmt.Errorf("%w: %v", ErrInvalidGuidelineBlockContent, err)
	}
	return nil
}

func decodeGuidelineBlock(raw json.RawMessage, target any) error {
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return errors.New("content must contain exactly one JSON object")
	}
	return nil
}

func requireGuidelineBlockType(actual, expected models.GuidelineBlockType) error {
	if actual != expected {
		return errors.New("payload type does not match block type")
	}
	return nil
}

func validateGuidelineTable(payload models.GuidelineTableBlockPayload) error {
	if len(payload.Columns) == 0 || containsBlank(payload.Columns) || len(payload.Rows) == 0 {
		return ErrInvalidGuidelineBlockContent
	}
	for _, row := range payload.Rows {
		if len(row) != len(payload.Columns) {
			return errors.New("table row width does not match columns")
		}
	}
	return nil
}

func validateGuidelineAlgorithm(payload models.GuidelineAlgorithmBlockPayload) error {
	if len(payload.Nodes) == 0 {
		return ErrInvalidGuidelineBlockContent
	}
	ids := make(map[string]struct{}, len(payload.Nodes))
	for _, node := range payload.Nodes {
		if blank(node.ID) || blank(node.Label) || blank(node.Kind) {
			return ErrInvalidGuidelineBlockContent
		}
		if _, exists := ids[node.ID]; exists {
			return errors.New("algorithm node IDs must be unique")
		}
		ids[node.ID] = struct{}{}
	}
	for _, node := range payload.Nodes {
		for _, next := range node.Next {
			if _, exists := ids[next]; !exists {
				return errors.New("algorithm edge references an unknown node")
			}
		}
	}
	return nil
}

func validGuidelineSeverity(value string) bool {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "standard", "important", "high", "critical":
		return true
	default:
		return false
	}
}

func containsBlank(values []string) bool {
	for _, value := range values {
		if blank(value) {
			return true
		}
	}
	return false
}

func blank(value string) bool { return strings.TrimSpace(value) == "" }
