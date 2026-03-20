package storage

import (
	"cloud.google.com/go/storage"
	"context"
	"fmt"
)

// Client は Cloud Storage への音声ファイルアップロードを担当する
type Client struct {
	gcs        *storage.Client
	bucket     *storage.BucketHandle
	bucketName string
}

// NewClient は Cloud Storage クライアントを初期化する
func NewClient(ctx context.Context, bucketName string) (*Client, error) {
	gcs, err := storage.NewClient(ctx)
	if err != nil {
		return nil, fmt.Errorf("storage.NewClient: %w", err)
	}

	return &Client{
		gcs:        gcs,
		bucket:     gcs.Bucket(bucketName),
		bucketName: bucketName,
	}, nil
}

// Close は内部の gRPC 接続を閉じる
func (c *Client) Close() error {
	return c.gcs.Close()
}

// UploadSong は音声データを Cloud Storage にアップロードし、公開 URL を返す
func (c *Client) UploadSong(ctx context.Context, chainID string, audioData []byte) (string, error) {
	objectPath := fmt.Sprintf("songs/%s/original.wav", chainID)

	wc := c.bucket.Object(objectPath).NewWriter(ctx)
	wc.ContentType = "audio/wav"
	wc.CacheControl = "public, max-age=31536000" // 1年キャッシュ

	if _, err := wc.Write(audioData); err != nil {
		_ = wc.Close()
		return "", fmt.Errorf("storage.UploadSong: write failed: %w", err)
	}

	if err := wc.Close(); err != nil {
		return "", fmt.Errorf("storage.UploadSong: close failed: %w", err)
	}

	url := fmt.Sprintf("https://storage.googleapis.com/%s/%s", c.bucketName, objectPath)
	return url, nil
}
