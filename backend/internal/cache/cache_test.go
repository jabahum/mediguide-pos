package cache

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/alicebob/miniredis/v2"
	"github.com/redis/go-redis/v9"
)

func TestStoreSetGetAndNamespaceInvalidation(t *testing.T) {
	server := miniredis.RunT(t)
	client := redis.NewClient(&redis.Options{Addr: server.Addr()})
	store := New(client, "test", true, 1024)
	ctx := context.Background()

	if err := store.Set(ctx, "guidelines", "list", map[string]int{"count": 2}, time.Minute); err != nil {
		t.Fatal(err)
	}
	var value map[string]int
	if err := store.Get(ctx, "guidelines", "list", &value); err != nil || value["count"] != 2 {
		t.Fatalf("unexpected cached value: %#v, %v", value, err)
	}
	if err := store.InvalidateNamespace(ctx, "guidelines"); err != nil {
		t.Fatal(err)
	}
	if err := store.Get(ctx, "guidelines", "list", &value); err != ErrMiss {
		t.Fatalf("expected miss after namespace invalidation, got %v", err)
	}
}

func TestGetOrLoadSuppressesConcurrentLoads(t *testing.T) {
	server := miniredis.RunT(t)
	client := redis.NewClient(&redis.Options{Addr: server.Addr()})
	store := New(client, "test", true, 1024)
	ctx := context.Background()
	var loads atomic.Int32
	start := make(chan struct{})
	var wait sync.WaitGroup

	for range 8 {
		wait.Add(1)
		go func() {
			defer wait.Done()
			<-start
			value, err := GetOrLoad(ctx, store, "reference", "regions", time.Minute, func() (string, error) {
				loads.Add(1)
				time.Sleep(10 * time.Millisecond)
				return "cached", nil
			})
			if err != nil || value != "cached" {
				t.Errorf("unexpected result %q, %v", value, err)
			}
		}()
	}
	close(start)
	wait.Wait()
	if loads.Load() != 1 {
		t.Fatalf("expected one load, got %d", loads.Load())
	}
}

func TestCorruptCacheEntryBecomesMiss(t *testing.T) {
	server := miniredis.RunT(t)
	client := redis.NewClient(&redis.Options{Addr: server.Addr()})
	store := New(client, "test", true, 1024)
	ctx := context.Background()
	key := store.dataKey("reference", 1, "regions")
	server.Set(key, "not-json")

	var target string
	if err := store.Get(ctx, "reference", "regions", &target); err != ErrMiss {
		t.Fatalf("expected corrupt entry to be a miss, got %v", err)
	}
	if server.Exists(key) {
		t.Fatal("corrupt entry was not deleted")
	}
}

func TestTTLExpirationAndErrorsAreNotCached(t *testing.T) {
	server := miniredis.RunT(t)
	client := redis.NewClient(&redis.Options{Addr: server.Addr()})
	store := New(client, "test", true, 1024)
	ctx := context.Background()

	if err := store.Set(ctx, "reference", "short", "value", time.Second); err != nil {
		t.Fatal(err)
	}
	server.FastForward(2 * time.Second)
	var target string
	if err := store.Get(ctx, "reference", "short", &target); err != ErrMiss {
		t.Fatalf("expected expired value to miss, got %v", err)
	}

	loads := 0
	load := func() (string, error) {
		loads++
		return "", errors.New("database unavailable")
	}
	for range 2 {
		if _, err := GetOrLoad(ctx, store, "reference", "error", time.Minute, load); err == nil {
			t.Fatal("expected loader error")
		}
	}
	if loads != 2 {
		t.Fatalf("loader errors were cached: %d loads", loads)
	}
}
