package usecase

import (
	"context"
	"errors"
	"testing"

	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/repository"
	"hackathon/internal/usecase/port"
)

// ─── スタブ実装 ───────────────────────────────────────────────────────────────

type stubLyriaJobRepo struct {
	pendingJobs []repository.OutboxLyriaJobDetail
	completed   []repository.SaveSongInput
	failed      []string // FailJob で記録された jobID
}

func (r *stubLyriaJobRepo) ClaimPendingJobs(_ context.Context, _ int) ([]repository.OutboxLyriaJobDetail, error) {
	return r.pendingJobs, nil
}

func (r *stubLyriaJobRepo) CompleteJob(_ context.Context, _, _ string, song repository.SaveSongInput) error {
	r.completed = append(r.completed, song)
	return nil
}

func (r *stubLyriaJobRepo) FailJob(_ context.Context, jobID string, _ string) error {
	r.failed = append(r.failed, jobID)
	return nil
}

type stubGeminiClient struct {
	analyzeErr  error
	moderateErr error
	harmful     bool
}

func (g *stubGeminiClient) AnalyzeLyrics(_ context.Context, _ string) (*port.LyricsAnalysis, error) {
	if g.analyzeErr != nil {
		return nil, g.analyzeErr
	}
	return &port.LyricsAnalysis{
		Mood:           "upbeat",
		Genre:          "j-pop",
		Tempo:          "medium",
		SuggestedTitle: "テスト曲",
	}, nil
}

func (g *stubGeminiClient) ModerateContent(_ context.Context, _ string) (*port.ModerationResult, error) {
	if g.moderateErr != nil {
		return nil, g.moderateErr
	}
	return &port.ModerationResult{IsHarmful: g.harmful}, nil
}

func (g *stubGeminiClient) GenerateTitle(_ context.Context, _ string, _ string) (string, error) {
	return "テスト曲", nil
}

type stubLyriaClient struct {
	generateErr error
}

func (l *stubLyriaClient) GenerateSong(_ context.Context, req *port.LyriaRequest) (*port.LyriaResponse, error) {
	if l.generateErr != nil {
		return nil, l.generateErr
	}
	return &port.LyriaResponse{
		AudioData:   []byte("dummy-audio"),
		Format:      "wav",
		DurationSec: req.DurationSec,
	}, nil
}

type stubSongUploader struct {
	uploadErr error
}

func (s *stubSongUploader) UploadSong(_ context.Context, chainID string, _ []byte) (string, error) {
	if s.uploadErr != nil {
		return "", s.uploadErr
	}
	return "https://storage.googleapis.com/mock/" + chainID + "/original.wav", nil
}

// ─── テスト ───────────────────────────────────────────────────────────────────

func TestProcessLyriaJobs_Success(t *testing.T) {
	jobRepo := &stubLyriaJobRepo{
		pendingJobs: []repository.OutboxLyriaJobDetail{
			{JobID: "job-1", ChainID: "chain-1", Lyrics: []string{"歌詞1", "歌詞2", "歌詞3", "歌詞4"}},
		},
	}

	uc := NewWorkerUsecase(
		&stubBleTokenRepo{byUserID: make(map[string]entity.BleToken), byToken: make(map[string]entity.BleToken)},
		jobRepo,
		&stubGeminiClient{},
		&stubLyriaClient{},
		&stubSongUploader{},
		45,
	)

	processed, err := uc.ProcessLyriaJobs(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if processed != 1 {
		t.Errorf("expected 1 processed job, got %d", processed)
	}
	if len(jobRepo.completed) != 1 {
		t.Fatalf("expected 1 completed song, got %d", len(jobRepo.completed))
	}
	if jobRepo.completed[0].Mood != "upbeat" {
		t.Errorf("expected mood=upbeat, got %q", jobRepo.completed[0].Mood)
	}
	if jobRepo.completed[0].DurationSec != 45 {
		t.Errorf("expected duration=45, got %d", jobRepo.completed[0].DurationSec)
	}
}

func TestProcessLyriaJobs_NoPendingJobs(t *testing.T) {
	jobRepo := &stubLyriaJobRepo{pendingJobs: nil}

	uc := NewWorkerUsecase(
		&stubBleTokenRepo{byUserID: make(map[string]entity.BleToken), byToken: make(map[string]entity.BleToken)},
		jobRepo,
		&stubGeminiClient{},
		&stubLyriaClient{},
		&stubSongUploader{},
		45,
	)

	processed, err := uc.ProcessLyriaJobs(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if processed != 0 {
		t.Errorf("expected 0 processed jobs, got %d", processed)
	}
}

func TestProcessLyriaJobs_HarmfulContent(t *testing.T) {
	jobRepo := &stubLyriaJobRepo{
		pendingJobs: []repository.OutboxLyriaJobDetail{
			{JobID: "job-harmful", ChainID: "chain-2", Lyrics: []string{"不適切な歌詞"}},
		},
	}

	uc := NewWorkerUsecase(
		&stubBleTokenRepo{byUserID: make(map[string]entity.BleToken), byToken: make(map[string]entity.BleToken)},
		jobRepo,
		&stubGeminiClient{harmful: true},
		&stubLyriaClient{},
		&stubSongUploader{},
		45,
	)

	processed, err := uc.ProcessLyriaJobs(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if processed != 0 {
		t.Errorf("expected 0 processed (harmful content), got %d", processed)
	}
	if len(jobRepo.failed) != 1 || jobRepo.failed[0] != "job-harmful" {
		t.Errorf("expected job-harmful to be failed, got %v", jobRepo.failed)
	}
}

func TestProcessLyriaJobs_LyriaError(t *testing.T) {
	jobRepo := &stubLyriaJobRepo{
		pendingJobs: []repository.OutboxLyriaJobDetail{
			{JobID: "job-err", ChainID: "chain-3", Lyrics: []string{"歌詞"}},
		},
	}

	uc := NewWorkerUsecase(
		&stubBleTokenRepo{byUserID: make(map[string]entity.BleToken), byToken: make(map[string]entity.BleToken)},
		jobRepo,
		&stubGeminiClient{},
		&stubLyriaClient{generateErr: errors.New("vertex ai timeout")},
		&stubSongUploader{},
		45,
	)

	processed, err := uc.ProcessLyriaJobs(context.Background())
	if err != nil {
		t.Fatalf("unexpected error at usecase level: %v", err)
	}
	if processed != 0 {
		t.Errorf("expected 0 processed (lyria error), got %d", processed)
	}
	if len(jobRepo.failed) != 1 {
		t.Errorf("expected 1 failed job, got %v", jobRepo.failed)
	}
}

func TestProcessLyriaJobs_MultipleJobs(t *testing.T) {
	jobRepo := &stubLyriaJobRepo{
		pendingJobs: []repository.OutboxLyriaJobDetail{
			{JobID: "job-A", ChainID: "chain-A", Lyrics: []string{"A1", "A2", "A3", "A4"}},
			{JobID: "job-B", ChainID: "chain-B", Lyrics: []string{"B1", "B2", "B3", "B4"}},
		},
	}

	uc := NewWorkerUsecase(
		&stubBleTokenRepo{byUserID: make(map[string]entity.BleToken), byToken: make(map[string]entity.BleToken)},
		jobRepo,
		&stubGeminiClient{},
		&stubLyriaClient{},
		&stubSongUploader{},
		45,
	)

	processed, err := uc.ProcessLyriaJobs(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if processed != 2 {
		t.Errorf("expected 2 processed jobs, got %d", processed)
	}
	if len(jobRepo.completed) != 2 {
		t.Errorf("expected 2 completed songs, got %d", len(jobRepo.completed))
	}
}
