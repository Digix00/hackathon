package storage

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"time"

	cloudstorage "cloud.google.com/go/storage"

	"hackathon/internal/usecase/port"
)

// GCSClient は Google Cloud Storage の StorageClient 実装。
type GCSClient struct {
	client     *cloudstorage.Client
	bucketName string
}

// NewGCSClient は GCSClient を生成する。ADC を使って認証する。
func NewGCSClient(ctx context.Context, bucketName string) (*GCSClient, error) {
	client, err := cloudstorage.NewClient(ctx)
	if err != nil {
		return nil, fmt.Errorf("gcs: failed to create client: %w", err)
	}
	return &GCSClient{client: client, bucketName: bucketName}, nil
}

// UploadSong は音声データを GCS にアップロードし、公開 URL を返す。
func (c *GCSClient) UploadSong(ctx context.Context, chainID string, audioData []byte, mimeType string) (string, error) {
	ext := "wav"
	if mimeType == "audio/mp3" || mimeType == "audio/mpeg" {
		ext = "mp3"
	}
	objectPath := fmt.Sprintf("songs/%s/original.%s", chainID, ext)

	wc := c.client.Bucket(c.bucketName).Object(objectPath).NewWriter(ctx)
	wc.ContentType = mimeType
	wc.CacheControl = "public, max-age=31536000"

	if _, err := io.Copy(wc, bytes.NewReader(audioData)); err != nil {
		_ = wc.Close()
		return "", fmt.Errorf("gcs: write failed: %w", err)
	}
	if err := wc.Close(); err != nil {
		return "", fmt.Errorf("gcs: close failed: %w", err)
	}

	return fmt.Sprintf("https://storage.googleapis.com/%s/%s", c.bucketName, objectPath), nil
}

// SignedURL は指定パスの署名付き URL（有効期限1時間）を生成する。
func (c *GCSClient) SignedURL(ctx context.Context, objectPath string) (string, error) {
	opts := &cloudstorage.SignedURLOptions{
		Method:  "GET",
		Expires: time.Now().Add(1 * time.Hour),
	}
	url, err := c.client.Bucket(c.bucketName).SignedURL(objectPath, opts)
	if err != nil {
		return "", fmt.Errorf("gcs: signed URL failed: %w", err)
	}
	return url, nil
}

// ─── MockStorageClient ────────────────────────────────────────────────────────

// MockStorageClient は開発環境で使うモック実装。
type MockStorageClient struct{}

var _ port.StorageClient = (*MockStorageClient)(nil)

func (m *MockStorageClient) UploadSong(_ context.Context, chainID string, _ []byte, _ string) (string, error) {
	return fmt.Sprintf("https://storage.googleapis.com/mock-bucket/songs/%s/original.wav", chainID), nil
}

func (m *MockStorageClient) SignedURL(_ context.Context, objectPath string) (string, error) {
	return "https://storage.googleapis.com/mock-bucket/" + objectPath + "?signed=true", nil
}
