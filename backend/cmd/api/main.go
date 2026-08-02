package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	_ "mediguide/docs"
	_ "mediguide/docs/versioned"
	"mediguide/internal/app"
	"mediguide/internal/config"

	"github.com/rs/zerolog/log"
)

// @title MediGuide Backend API
// @version 1.0
// @description Offline-first clinical guideline backend API for MediGuide.
// @termsOfService https://mediguide.local/terms
// @contact.name MediGuide Backend
// @contact.email admin@mediguide.local
// @license.name Proprietary
// @BasePath /
// @schemes http https
// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Bearer access token. Example: Bearer <token>
func main() {
	cfg := config.Load()

	if len(cfg.JWTSecret) < 32 {
		log.Fatal().Msg("JWT_SECRET must be at least 32 characters long to ensure token security")
	}

	application, err := app.New(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to initialize app")
	}
	defer func() {
		if err := application.Close(); err != nil {
			log.Error().Err(err).Msg("failed to close application resources")
		}
	}()

	srv := &http.Server{
		Addr:              fmt.Sprintf(":%s", cfg.Port),
		Handler:           application.Router,
		ReadHeaderTimeout: 10 * time.Second,
	}

	go func() {
		log.Info().Str("addr", srv.Addr).Msg("MediGuide API started")
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Err(err).Msg("server failed")
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Error().Err(err).Msg("server forced shutdown")
	}
}
