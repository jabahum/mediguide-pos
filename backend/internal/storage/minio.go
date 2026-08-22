package storage

import (
	"context"
	"errors"
	"io"
	"net/url"
	"time"

	"mediguide/internal/config"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type MinioStore struct {
	client *minio.Client
	bucket string
}

func NewMinioStore(cfg config.Config) (*MinioStore, error) {
	client, err := minio.New(cfg.S3Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.S3AccessKey, cfg.S3SecretKey, ""),
		Secure: cfg.S3UseSSL,
	})
	if err != nil {
		return nil, err
	}
	ctx := context.Background()
	exists, err := client.BucketExists(ctx, cfg.S3Bucket)
	if err != nil {
		return nil, err
	}
	if !exists {
		if err := client.MakeBucket(ctx, cfg.S3Bucket, minio.MakeBucketOptions{}); err != nil {
			return nil, err
		}
	}
	return &MinioStore{client: client, bucket: cfg.S3Bucket}, nil
}

func (s *MinioStore) Put(ctx context.Context, key string, r io.Reader, size int64, contentType string) error {
	_, err := s.client.PutObject(ctx, s.bucket, key, r, size, minio.PutObjectOptions{ContentType: contentType})
	return err
}
func (s *MinioStore) Get(ctx context.Context, key string) (io.ReadCloser, error) {
	return s.client.GetObject(ctx, s.bucket, key, minio.GetObjectOptions{})
}
func (s *MinioStore) Delete(ctx context.Context, key string) error {
	return s.client.RemoveObject(ctx, s.bucket, key, minio.RemoveObjectOptions{})
}
func (s *MinioStore) PresignGet(ctx context.Context, key string, expiry time.Duration) (*url.URL, error) {
	return s.client.PresignedGetObject(ctx, s.bucket, key, expiry, nil)
}
func (s *MinioStore) Health(ctx context.Context) error {
	exists, err := s.client.BucketExists(ctx, s.bucket)
	if err != nil {
		return err
	}
	if !exists {
		return errors.New("managed report bucket is unavailable")
	}
	return nil
}
