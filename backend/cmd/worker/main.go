package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"

	"hackathon/config"
	infragemini "hackathon/internal/infra/gemini"
	infralyria "hackathon/internal/infra/lyria"
	"hackathon/internal/infra/rdb"
	infrastorage "hackathon/internal/infra/storage"
	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/repository"
	"hackathon/internal/domain/vo"
	"hackathon/internal/usecase/port"
)

func main() {
	ctx := context.Background()

	interval := 30 * time.Second
	if os.Getenv("WORKER_ONESHOT") == "true" {
		log.Println("worker oneshot: boot ok")
		return
	}

	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("worker: config load failed: %v", err)
	}

	db, err := rdb.Open(cfg.DatabaseURL, cfg.GoEnv)
	if err != nil {
		log.Fatalf("worker: db open failed: %v", err)
	}
	sqlDB, _ := db.DB()
	defer sqlDB.Close()

	if err := rdb.Migrate(db); err != nil {
		log.Fatalf("worker: db migrate failed: %v", err)
	}

	var geminiClient port.GeminiClient
	var lyriaClient port.LyriaClient
	var storageClient port.StorageClient

	if cfg.GoEnv == "production" && cfg.VertexAIProjectID != "" {
		geminiClient, err = infragemini.NewClient(ctx, cfg.VertexAIProjectID, cfg.VertexAILocation, cfg.GeminiModelID)
		if err != nil {
			log.Fatalf("worker: gemini client init failed: %v", err)
		}
		lyriaClient, err = infralyria.NewClient(ctx, cfg.VertexAIProjectID, cfg.VertexAILocation, cfg.LyriaModelID)
		if err != nil {
			log.Fatalf("worker: lyria client init failed: %v", err)
		}
		storageClient, err = infrastorage.NewGCSClient(ctx, cfg.GCSBucketName)
		if err != nil {
			log.Fatalf("worker: gcs client init failed: %v", err)
		}
	} else {
		log.Println("worker: using mock clients (non-production env or missing VERTEX_AI_PROJECT_ID)")
		geminiClient = &mockGeminiClient{}
		lyriaClient = &infralyria.MockClient{}
		storageClient = &infrastorage.MockStorageClient{}
	}

	processor := &lyriaJobProcessor{
		outboxRepo:    rdb.NewOutboxLyriaJobRepository(db),
		chainRepo:     rdb.NewLyricChainRepository(db),
		entryRepo:     rdb.NewLyricEntryRepository(db),
		songRepo:      rdb.NewGeneratedSongRepository(db),
		geminiClient:  geminiClient,
		lyriaClient:   lyriaClient,
		storageClient: storageClient,
		defaultDurSec: cfg.LyriaDefaultDurationS,
	}

	log.Printf("worker started: tick interval=%s", interval)
	for {
		if err := processor.processPendingJobs(ctx); err != nil {
			log.Printf("worker: processPendingJobs error: %v", err)
		}
		time.Sleep(interval)
	}
}

// ─── lyriaJobProcessor ────────────────────────────────────────────────────────

type lyriaJobProcessor struct {
	outboxRepo    repository.OutboxLyriaJobRepository
	chainRepo     repository.LyricChainRepository
	entryRepo     repository.LyricEntryRepository
	songRepo      repository.GeneratedSongRepository
	geminiClient  port.GeminiClient
	lyriaClient   port.LyriaClient
	storageClient port.StorageClient
	defaultDurSec int
}

func (p *lyriaJobProcessor) processPendingJobs(ctx context.Context) error {
	jobs, err := p.outboxRepo.ListPending(ctx, 5)
	if err != nil {
		return fmt.Errorf("list pending jobs: %w", err)
	}
	if len(jobs) == 0 {
		log.Println("worker: no pending lyria jobs")
		return nil
	}

	for _, job := range jobs {
		if err := p.processJob(ctx, job); err != nil {
			log.Printf("worker: job %s failed: %v", job.ID, err)
		}
	}
	return nil
}

func (p *lyriaJobProcessor) processJob(ctx context.Context, job entity.OutboxLyriaJob) error {
	if err := p.outboxRepo.SetProcessing(ctx, job.ID); err != nil {
		return fmt.Errorf("set processing: %w", err)
	}

	log.Printf("worker: processing lyria job %s for chain %s", job.ID, job.ChainID)

	if err := p.generateSong(ctx, job.ChainID); err != nil {
		errMsg := err.Error()
		_ = p.outboxRepo.SetFailed(ctx, job.ID, errMsg)
		// chain status を failed に更新
		_, _, _ = p.chainRepo.IncrementParticipantCount(ctx, job.ChainID, 0) // no-op count
		log.Printf("worker: song generation failed for chain %s: %v", job.ChainID, err)
		return err
	}

	now := time.Now().UTC()
	_ = p.outboxRepo.SetCompleted(ctx, job.ID, now)
	log.Printf("worker: song generation completed for chain %s", job.ChainID)
	return nil
}

func (p *lyriaJobProcessor) generateSong(ctx context.Context, chainID string) error {
	// 1. 歌詞エントリを取得して連結
	entries, err := p.entryRepo.FindByChainID(ctx, chainID)
	if err != nil {
		return fmt.Errorf("find entries: %w", err)
	}
	if len(entries) == 0 {
		return fmt.Errorf("no entries for chain %s", chainID)
	}

	lyricsLines := make([]string, len(entries))
	for i, e := range entries {
		lyricsLines[i] = e.Content
	}
	lyrics := strings.Join(lyricsLines, "\n")

	// 2. Gemini でモデレーション
	modResult, err := p.geminiClient.ModerateContent(ctx, lyrics)
	if err != nil {
		log.Printf("worker: moderation error (skipping): %v", err)
	} else if modResult != nil && modResult.IsHarmful {
		return fmt.Errorf("content flagged as harmful: categories=%v", modResult.Categories)
	}

	// 3. Gemini で歌詞分析
	analysis, err := p.geminiClient.AnalyzeLyrics(ctx, lyrics)
	if err != nil {
		log.Printf("worker: analysis error (using defaults): %v", err)
		analysis = &port.LyricsAnalysis{
			Mood:           "nostalgic",
			Genre:          "j-pop",
			Tempo:          "medium",
			SuggestedTitle: "歌詞から生まれた曲",
		}
	}

	// 4. Lyria で楽曲生成
	durSec := p.defaultDurSec
	if durSec <= 0 {
		durSec = 45
	}

	lyriaResp, err := p.lyriaClient.GenerateSong(ctx, &port.LyriaRequest{
		Lyrics:      lyrics,
		Mood:        analysis.Mood,
		Genre:       analysis.Genre,
		Tempo:       analysis.Tempo,
		DurationSec: durSec,
		Title:       analysis.SuggestedTitle,
	})
	if err != nil {
		return fmt.Errorf("lyria generate: %w", err)
	}

	// 5. GCS にアップロード
	mimeType := "audio/wav"
	if lyriaResp.Format == "mp3" {
		mimeType = "audio/mpeg"
	}
	audioURL, err := p.storageClient.UploadSong(ctx, chainID, lyriaResp.AudioData, mimeType)
	if err != nil {
		return fmt.Errorf("storage upload: %w", err)
	}

	// 6. GeneratedSong を更新
	song, err := p.songRepo.FindByChainID(ctx, chainID)
	if err != nil {
		// 見つからなければ新規作成
		song = entity.GeneratedSong{
			ID:      uuid.NewString(),
			ChainID: chainID,
		}
	}
	now := time.Now().UTC()
	durSecPtr := lyriaResp.DurationSec
	song.Title = &analysis.SuggestedTitle
	song.AudioURL = &audioURL
	song.DurationSec = &durSecPtr
	song.Mood = &analysis.Mood
	song.Genre = &analysis.Genre
	song.Status = vo.GeneratedSongStatusCompleted
	song.GeneratedAt = &now

	if song.ID == "" {
		_, err = p.songRepo.Create(ctx, song)
	} else {
		err = p.songRepo.Update(ctx, song)
	}
	return err
}

// ─── Mock Gemini ──────────────────────────────────────────────────────────────

type mockGeminiClient struct{}

func (m *mockGeminiClient) AnalyzeLyrics(_ context.Context, _ string) (*port.LyricsAnalysis, error) {
	return &port.LyricsAnalysis{
		Mood:           "nostalgic",
		SecondaryMoods: []string{"穏やか", "切ない"},
		Genre:          "j-pop",
		Tempo:          "medium",
		SuggestedTitle: "思い出の歌",
		Keywords:       []string{"空", "風", "記憶"},
		Language:       "ja",
	}, nil
}

func (m *mockGeminiClient) ModerateContent(_ context.Context, _ string) (*port.ModerationResult, error) {
	return &port.ModerationResult{IsHarmful: false, Confidence: 0.01}, nil
}
