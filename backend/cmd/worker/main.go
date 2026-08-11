package main

import (
	"context"
	"fmt"
	"strings"
	"time"

	"mediguide/internal/aiworkergrpc"
	"mediguide/internal/config"
	"mediguide/internal/db"
	"mediguide/internal/models"

	"github.com/rs/zerolog/log"
	"gorm.io/gorm"
)

func main() {
	cfg := config.Load()
	database, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatal().Err(err).Msg("db connect failed")
	}

	grpcAddr := strings.TrimSpace(cfg.AIWorkerGRPCAddr)
	if grpcAddr == "" {
		log.Fatal().Msg("AI worker gRPC address is not configured")
	}

	log.Info().Str("worker_grpc_addr", grpcAddr).Msg("ingestion dispatcher started")

	for {
		job, claimed, err := claimQueuedJob(database)
		if err != nil {
			log.Error().Err(err).Msg("failed to claim ingestion job")
			time.Sleep(10 * time.Second)
			continue
		}
		if !claimed {
			time.Sleep(10 * time.Second)
			continue
		}

		log.Info().Str("job_id", job.ID.String()).Msg("dispatching ingestion job to ai-worker")
		if err := dispatchIngestionJob(grpcAddr, cfg.AIWorkerSecret, job.ID.String()); err != nil {
			log.Error().Err(err).Str("job_id", job.ID.String()).Msg("ai-worker dispatch failed")
			markJobFailed(database, job.ID.String(), err.Error())
		}
	}
}

func claimQueuedJob(database *gorm.DB) (*models.IngestionJob, bool, error) {
	var job models.IngestionJob
	if err := database.Where("status = ? AND job_type IN ?", "queued", []string{"pdf_ingestion", "markdown_ingestion"}).Order("created_at asc").First(&job).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, false, nil
		}
		return nil, false, err
	}

	res := database.Model(&models.IngestionJob{}).
		Where("id = ? AND status = ?", job.ID, "queued").
		Updates(map[string]any{
			"status":     "waiting_external_worker",
			"started_at": time.Now(),
		})
	if res.Error != nil {
		return nil, false, res.Error
	}
	if res.RowsAffected == 0 {
		return nil, false, nil
	}
	return &job, true, nil
}

func dispatchIngestionJob(grpcAddr, secret, jobID string) error {
	dialCtx, dialCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer dialCancel()

	client, err := aiworkergrpc.NewClient(dialCtx, grpcAddr, secret)
	if err != nil {
		return err
	}
	defer client.Close()

	callCtx, callCancel := context.WithTimeout(context.Background(), 15*time.Minute)
	defer callCancel()

	resp, err := client.RunIngestionJob(callCtx, jobID)
	if err != nil {
		return err
	}
	if strings.TrimSpace(resp.Status) == "" {
		return fmt.Errorf("AI worker returned an empty status for job %s", jobID)
	}
	return nil
}

func markJobFailed(database *gorm.DB, jobID string, message string) {
	if err := database.Model(&models.IngestionJob{}).
		Where("id = ?", jobID).
		Updates(map[string]any{
			"status":       "failed",
			"error":        truncateError(message),
			"completed_at": time.Now(),
		}).Error; err != nil {
		log.Error().Err(err).Str("job_id", jobID).Msg("failed to mark ingestion job as failed")
	}
}

func truncateError(message string) string {
	message = strings.TrimSpace(message)
	if len(message) <= 4000 {
		return message
	}
	return message[:4000]
}
