package main

import (
	"context"
	"fmt"

	"go.uber.org/zap"
	"gorm.io/gorm"

	"hackathon/config"
	infragemini "hackathon/internal/infra/gemini"
	infralyria "hackathon/internal/infra/lyria"
	"hackathon/internal/infra/rdb"
	infrastorage "hackathon/internal/infra/storage"
	"hackathon/internal/usecase"
	"hackathon/internal/usecase/port"
)

func buildDependencies(ctx context.Context, db *gorm.DB, cfg *config.WorkerConfig, log *zap.Logger) (usecase.WorkerUsecase, func()) {
	bleTokenRepo := rdb.NewBleTokenRepository(db)
	lyriaJobRepo := rdb.NewLyriaJobRepository(db)

	var geminiClient port.GeminiClient
	var lyriaClient port.LyriaClient
	var songUploader usecase.SongUploader
	var cleanup func()

	// 開発環境またはプロジェクトID未設定時はモッククライアントを使用
	if cfg.GoEnv == "development" || cfg.VertexAIProjectID == "" {
		log.Info("using mock Lyria and Gemini clients (development mode)")
		geminiClient = newMockGeminiClient()
		lyriaClient = infralyria.NewMockClient()
		songUploader = newMockSongUploader()
		cleanup = func() {}
	} else {
		realGeminiClient, err := infragemini.NewClient(ctx, cfg.VertexAIProjectID, cfg.VertexAILocation, cfg.GeminiModelID)
		if err != nil {
			log.Fatal("failed to create Gemini client", zap.Error(err))
		}
		geminiClient = realGeminiClient

		realLyriaClient, err := infralyria.NewClient(ctx, cfg.VertexAIProjectID, cfg.VertexAILocation, cfg.LyriaModelID)
		if err != nil {
			log.Fatal("failed to create Lyria client", zap.Error(err))
		}
		lyriaClient = realLyriaClient

		storageClient, err := infrastorage.NewClient(ctx, cfg.AudioBucketName)
		if err != nil {
			log.Fatal("failed to create Storage client", zap.Error(err))
		}
		songUploader = storageClient

		cleanup = func() {
			if err := realGeminiClient.Close(); err != nil {
				log.Warn("failed to close Gemini client", zap.Error(err))
			}
			if err := realLyriaClient.Close(); err != nil {
				log.Warn("failed to close Lyria client", zap.Error(err))
			}
			if err := storageClient.Close(); err != nil {
				log.Warn("failed to close Storage client", zap.Error(err))
			}
		}
	}

	return usecase.NewWorkerUsecase(
		bleTokenRepo,
		lyriaJobRepo,
		geminiClient,
		lyriaClient,
		songUploader,
		cfg.LyriaDefaultDuration,
	), cleanup
}

// mockGeminiClient は開発環境用のモック Gemini クライアント
type mockGeminiClient struct{}

func newMockGeminiClient() port.GeminiClient { return &mockGeminiClient{} }

func (m *mockGeminiClient) AnalyzeLyrics(_ context.Context, _ string) (*port.LyricsAnalysis, error) {
	return &port.LyricsAnalysis{
		Mood:           "upbeat",
		SecondaryMoods: []string{"明るい", "楽しい"},
		Genre:          "j-pop",
		Tempo:          "medium",
		SuggestedTitle: "テスト楽曲",
		Keywords:       []string{"テスト", "開発"},
		Language:       "ja",
	}, nil
}

func (m *mockGeminiClient) ModerateContent(_ context.Context, _ string) (*port.ModerationResult, error) {
	return &port.ModerationResult{IsHarmful: false, Confidence: 0.0}, nil
}

func (m *mockGeminiClient) GenerateTitle(_ context.Context, _ string, _ string) (string, error) {
	return "テスト楽曲", nil
}

// mockSongUploader は開発環境用のモック Storage クライアント
type mockSongUploader struct{}

func newMockSongUploader() usecase.SongUploader { return &mockSongUploader{} }

func (m *mockSongUploader) UploadSong(_ context.Context, chainID string, _ []byte) (string, error) {
	return fmt.Sprintf("https://storage.googleapis.com/mock-bucket/songs/%s/original.wav", chainID), nil
}
