package port

import "context"

// StorageClient はオブジェクトストレージへのアップロード/署名 URL 生成インターフェース。
type StorageClient interface {
	// UploadSong は音声データを指定 chain_id のパスにアップロードし、公開 URL を返す。
	UploadSong(ctx context.Context, chainID string, audioData []byte, mimeType string) (publicURL string, err error)

	// SignedURL は指定パスの一時署名付き URL を生成する（有効期限: 1 時間）。
	SignedURL(ctx context.Context, objectPath string) (string, error)
}
