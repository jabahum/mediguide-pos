package redisx

import (
	"context"
	"fmt"
	"time"

	"mediguide/internal/config"

	"github.com/redis/go-redis/v9"
)

func NewClient(cfg config.Config) (*redis.Client, error) {
	options, err := redis.ParseURL(cfg.RedisURL)
	if err != nil {
		return nil, fmt.Errorf("parse REDIS_URL: %w", err)
	}
	options.DialTimeout = durationMS(cfg.RedisConnectTimeout, 2*time.Second)
	options.ReadTimeout = durationMS(cfg.RedisReadTimeout, time.Second)
	options.WriteTimeout = durationMS(cfg.RedisWriteTimeout, time.Second)
	return redis.NewClient(options), nil
}

func Ping(ctx context.Context, client *redis.Client) error {
	if client == nil {
		return fmt.Errorf("redis client is not configured")
	}
	return client.Ping(ctx).Err()
}

func durationMS(value int, fallback time.Duration) time.Duration {
	if value <= 0 {
		return fallback
	}
	return time.Duration(value) * time.Millisecond
}
