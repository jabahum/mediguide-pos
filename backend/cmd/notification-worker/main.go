package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/db"
	"mediguide/internal/services"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
)

func main() {
	cfg := config.Load()
	database, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatal().Err(err).Msg("notification worker database connection failed")
	}
	sqlDB, err := database.DB()
	if err != nil {
		log.Fatal().Err(err).Msg("notification worker database handle failed")
	}
	defer sqlDB.Close()
	firebaseService, err := services.NewFirebaseService(database, cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("notification worker Firebase initialization failed")
	}
	worker := services.NotificationOutboxService{
		DB: database, Firebase: firebaseService, WorkerID: uuid.NewString(),
		BatchSize: cfg.NotificationWorkerBatchSize, MaxConcurrency: cfg.NotificationWorkerConcurrency,
		MaxAge:        time.Duration(cfg.NotificationWorkerMaxAgeHours) * time.Hour,
		LeaseDuration: time.Duration(cfg.NotificationWorkerLeaseSeconds) * time.Second,
	}

	ctx, cancel := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer cancel()
	server := &http.Server{Addr: fmt.Sprintf(":%s", cfg.NotificationWorkerPort), ReadHeaderTimeout: 5 * time.Second, Handler: workerHealthHandler(sqlDB.PingContext, firebaseService.Enabled)}
	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("notification worker health server failed")
		}
	}()

	poll := time.Duration(cfg.NotificationWorkerPollMS) * time.Millisecond
	if poll < 100*time.Millisecond {
		poll = time.Second
	}
	ticker := time.NewTicker(poll)
	pruneTicker := time.NewTicker(24 * time.Hour)
	defer ticker.Stop()
	defer pruneTicker.Stop()
	log.Info().Str("worker_id", worker.WorkerID).Int("batch_size", worker.BatchSize).Int("concurrency", worker.MaxConcurrency).Msg("notification delivery worker started")
	if count, err := worker.PruneStaleDevices(); err != nil {
		log.Error().Err(err).Msg("initial stale Firebase device pruning failed")
	} else if count > 0 {
		log.Info().Int64("pruned_devices", count).Msg("stale Firebase devices disabled")
	}
	for {
		select {
		case <-ctx.Done():
			shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 15*time.Second)
			defer shutdownCancel()
			_ = server.Shutdown(shutdownCtx)
			log.Info().Msg("notification delivery worker stopped")
			return
		case <-ticker.C:
			batchCtx, batchCancel := context.WithTimeout(ctx, 45*time.Second)
			result, err := worker.ProcessBatch(batchCtx)
			batchCancel()
			if err != nil && ctx.Err() == nil {
				log.Error().Err(err).Msg("notification delivery batch failed")
			} else if result != nil && result.Claimed > 0 {
				log.Info().Int("claimed", result.Claimed).Int("accepted", result.Accepted).Int("retried", result.Retried).Int("failed", result.Failed).Msg("notification delivery batch completed")
			}
		case <-pruneTicker.C:
			count, err := worker.PruneStaleDevices()
			if err != nil {
				log.Error().Err(err).Msg("stale Firebase device pruning failed")
			} else if count > 0 {
				log.Info().Int64("pruned_devices", count).Msg("stale Firebase devices disabled")
			}
		}
	}
}

func workerHealthHandler(ping func(context.Context) error, firebaseEnabled func() bool) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "service": "notification-worker"})
	})
	mux.HandleFunc("/readyz", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		if err := ping(ctx); err != nil {
			writeJSON(w, http.StatusServiceUnavailable, map[string]any{"ok": false, "reason": "db_unavailable"})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"ok": true, "firebase_configured": firebaseEnabled()})
	})
	return mux
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}
