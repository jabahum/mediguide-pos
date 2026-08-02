package cache

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"math/rand/v2"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog/log"
	"golang.org/x/sync/singleflight"
)

var ErrMiss = errors.New("cache miss")

type Store struct {
	client   redis.UniversalClient
	prefix   string
	enabled  bool
	maxBytes int
	group    singleflight.Group
	metrics  cacheMetrics
}

type cacheMetrics struct {
	hits, misses, errors, decodeErrors, invalidations, loads, loadNanos atomic.Uint64
}

type MetricsSnapshot struct {
	Hits, Misses, Errors, DecodeErrors, Invalidations, Loads, LoadNanoseconds uint64
}

func (s *Store) Metrics() MetricsSnapshot {
	if s == nil {
		return MetricsSnapshot{}
	}
	return MetricsSnapshot{
		Hits: s.metrics.hits.Load(), Misses: s.metrics.misses.Load(), Errors: s.metrics.errors.Load(),
		DecodeErrors: s.metrics.decodeErrors.Load(), Invalidations: s.metrics.invalidations.Load(),
		Loads: s.metrics.loads.Load(), LoadNanoseconds: s.metrics.loadNanos.Load(),
	}
}

type envelope struct {
	Version int             `json:"version"`
	Data    json.RawMessage `json:"data"`
}

func New(client redis.UniversalClient, prefix string, enabled bool, maxBytes int) *Store {
	if maxBytes <= 0 {
		maxBytes = 1_048_576
	}
	return &Store{
		client: client, prefix: strings.TrimSuffix(prefix, ":"), enabled: enabled, maxBytes: maxBytes,
	}
}

func (s *Store) Enabled() bool { return s != nil && s.enabled && s.client != nil }

func (s *Store) Get(ctx context.Context, namespace, key string, target any) error {
	if !s.Enabled() {
		log.Debug().Str("cache_namespace", namespace).Str("cache_result", "bypass").Msg("cache lookup")
		return ErrMiss
	}
	version := s.namespaceVersion(ctx, namespace)
	dataKey := s.dataKey(namespace, version, key)
	payload, err := s.client.Get(ctx, dataKey).Bytes()
	if err != nil {
		s.metrics.misses.Add(1)
		if !errors.Is(err, redis.Nil) {
			s.metrics.errors.Add(1)
			log.Warn().Err(err).Str("cache_namespace", namespace).Str("cache_result", "error").Msg("cache lookup failed")
		} else {
			log.Debug().Str("cache_namespace", namespace).Str("cache_result", "miss").Msg("cache lookup")
		}
		return ErrMiss
	}
	var value envelope
	if json.Unmarshal(payload, &value) != nil || value.Version != 1 || json.Unmarshal(value.Data, target) != nil {
		s.metrics.misses.Add(1)
		s.metrics.decodeErrors.Add(1)
		log.Warn().Str("cache_namespace", namespace).Str("cache_result", "decode_error").Msg("invalid cache entry removed")
		_ = s.client.Del(ctx, dataKey).Err()
		return ErrMiss
	}
	s.metrics.hits.Add(1)
	log.Debug().Str("cache_namespace", namespace).Str("cache_result", "hit").Msg("cache lookup")
	return nil
}

func (s *Store) Set(ctx context.Context, namespace, key string, value any, ttl time.Duration) error {
	if !s.Enabled() {
		return nil
	}
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	payload, err := json.Marshal(envelope{Version: 1, Data: data})
	if err != nil {
		return err
	}
	if len(payload) > s.maxBytes {
		return nil
	}
	version := s.namespaceVersion(ctx, namespace)
	if err := s.client.Set(ctx, s.dataKey(namespace, version, key), payload, jitter(ttl)).Err(); err != nil {
		s.metrics.errors.Add(1)
		log.Warn().Err(err).Str("cache_namespace", namespace).Str("cache_result", "error").Msg("cache write failed")
		return err
	}
	return nil
}

func (s *Store) Delete(ctx context.Context, namespace, key string) error {
	if !s.Enabled() {
		return nil
	}
	version := s.namespaceVersion(ctx, namespace)
	return s.client.Del(ctx, s.dataKey(namespace, version, key)).Err()
}

func (s *Store) InvalidateNamespace(ctx context.Context, namespace string) error {
	if !s.Enabled() {
		return nil
	}
	if err := s.client.Incr(ctx, s.versionKey(namespace)).Err(); err != nil {
		s.metrics.errors.Add(1)
		return err
	}
	s.metrics.invalidations.Add(1)
	log.Debug().Str("cache_namespace", namespace).Msg("cache namespace invalidated")
	return nil
}

func GetOrLoad[T any](ctx context.Context, store *Store, namespace, key string, ttl time.Duration, load func() (T, error)) (T, error) {
	var zero T
	if store != nil {
		var cached T
		if store.Get(ctx, namespace, key, &cached) == nil {
			return cached, nil
		}
	} else {
		return load()
	}

	value, err, _ := store.group.Do(namespace+":"+HashKey(key), func() (any, error) {
		var cached T
		if store.Get(ctx, namespace, key, &cached) == nil {
			return cached, nil
		}
		started := time.Now()
		loaded, loadErr := load()
		store.metrics.loads.Add(1)
		loadDuration := time.Since(started)
		store.metrics.loadNanos.Add(uint64(loadDuration))
		log.Debug().Str("cache_namespace", namespace).Str("cache_result", "load").Dur("cache_load_duration", loadDuration).Msg("cache load completed")
		if loadErr == nil {
			_ = store.Set(ctx, namespace, key, loaded, ttl)
		}
		return loaded, loadErr
	})
	if err != nil {
		return zero, err
	}
	return value.(T), nil
}

func HashKey(value string) string {
	sum := sha256.Sum256([]byte(value))
	return hex.EncodeToString(sum[:])
}

func (s *Store) namespaceVersion(ctx context.Context, namespace string) int64 {
	value, err := s.client.Get(ctx, s.versionKey(namespace)).Int64()
	if errors.Is(err, redis.Nil) {
		if s.client.SetNX(ctx, s.versionKey(namespace), 1, 0).Val() {
			return 1
		}
		value, err = s.client.Get(ctx, s.versionKey(namespace)).Int64()
	}
	if err != nil || value < 1 {
		return 1
	}
	return value
}

func (s *Store) versionKey(namespace string) string {
	return s.prefix + ":cache-version:" + HashKey(namespace)
}

func (s *Store) dataKey(namespace string, version int64, key string) string {
	return s.prefix + ":cache:" + HashKey(namespace) + ":v" + strconv.FormatInt(version, 10) + ":" + HashKey(key)
}

func jitter(ttl time.Duration) time.Duration {
	if ttl <= 0 {
		ttl = 5 * time.Minute
	}
	maximum := ttl / 10
	if maximum <= 0 {
		return ttl
	}
	return ttl + time.Duration(rand.Int64N(int64(maximum)+1))
}
