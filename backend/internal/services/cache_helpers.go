package services

import (
	"context"
	"encoding/json"
	"time"

	cachepkg "mediguide/internal/cache"
)

func cachedServiceValue[T any](store *cachepkg.Store, namespace string, key any, ttl time.Duration, load func() (T, error)) (T, error) {
	encoded, err := json.Marshal(key)
	if err != nil {
		return load()
	}
	return cachepkg.GetOrLoad(context.Background(), store, namespace, string(encoded), ttl, load)
}

func invalidateServiceCaches(store *cachepkg.Store, namespaces ...string) {
	if store == nil {
		return
	}
	for _, namespace := range namespaces {
		_ = store.InvalidateNamespace(context.Background(), namespace)
	}
}
