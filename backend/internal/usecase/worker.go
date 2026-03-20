package usecase

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"

	"hackathon/internal/domain/repository"
	"hackathon/internal/usecase/port"
)

// ErrHarmfulContent は有害コンテンツ検出による永続的エラーを示す。
// このエラーは歌詞の内容が原因であるため、リトライしても結果は変わらない。
var ErrHarmfulContent = errors.New("harmful content detected")

// SongUploader は音声ファイルのアップロードを担うインターフェース
type SongUploader interface {
	UploadSong(ctx context.Context, chainID string, audioData []byte) (string, error)
}

type WorkerUsecase interface {
	// DeleteExpiredBleTokens physically deletes all BLE tokens that have passed their valid_to time.
	// Returns the number of rows deleted.
	DeleteExpiredBleTokens(ctx context.Context) (int64, error)

	// ProcessLyriaJobs は OutboxLyriaJob キューを処理し、楽曲を生成して保存する。
	// 処理したジョブ数を返す。
	ProcessLyriaJobs(ctx context.Context) (int, error)
}

type workerUsecase struct {
	bleTokenRepo  repository.BleTokenRepository
	lyriaJobRepo  repository.LyriaJobRepository
	geminiClient  port.GeminiClient
	lyriaClient   port.LyriaClient
	songUploader  SongUploader
	defaultDurSec int
}

// NewWorkerUsecase は WorkerUsecase を初期化する
func NewWorkerUsecase(
	bleTokenRepo repository.BleTokenRepository,
	lyriaJobRepo repository.LyriaJobRepository,
	geminiClient port.GeminiClient,
	lyriaClient port.LyriaClient,
	songUploader SongUploader,
	defaultDurSec int,
) WorkerUsecase {
	if defaultDurSec <= 0 {
		defaultDurSec = 45
	}
	return &workerUsecase{
		bleTokenRepo:  bleTokenRepo,
		lyriaJobRepo:  lyriaJobRepo,
		geminiClient:  geminiClient,
		lyriaClient:   lyriaClient,
		songUploader:  songUploader,
		defaultDurSec: defaultDurSec,
	}
}

func (u *workerUsecase) DeleteExpiredBleTokens(ctx context.Context) (int64, error) {
	return u.bleTokenRepo.DeleteExpired(ctx)
}

// ProcessLyriaJobs は pending 状態のジョブを最大 5 件処理する
func (u *workerUsecase) ProcessLyriaJobs(ctx context.Context) (int, error) {
	jobs, err := u.lyriaJobRepo.ClaimPendingJobs(ctx, 5)
	if err != nil {
		return 0, fmt.Errorf("ProcessLyriaJobs: claim failed: %w", err)
	}

	processed := 0
	for _, job := range jobs {
		if err := u.processJob(ctx, job); err != nil {
			// 有害コンテンツは歌詞が不変なため即座に永続失敗とし、不要なリトライを防ぐ
			permanent := errors.Is(err, ErrHarmfulContent)
			_ = u.lyriaJobRepo.FailJob(ctx, job.JobID, err.Error(), permanent)
			continue
		}
		processed++
	}

	return processed, nil
}

// processJob は単一のジョブを Gemini 分析 → Lyria 生成 → Storage 保存 → DB 更新 の順で処理する
func (u *workerUsecase) processJob(ctx context.Context, job repository.OutboxLyriaJobDetail) error {
	lyrics := strings.Join(job.Lyrics, "\n")

	// コンテンツモデレーション
	modResult, err := u.geminiClient.ModerateContent(ctx, lyrics)
	if err != nil {
		return fmt.Errorf("moderation failed: %w", err)
	}
	if modResult.IsHarmful {
		return fmt.Errorf("%w: categories: %v", ErrHarmfulContent, modResult.Categories)
	}

	// 歌詞分析
	analysis, err := u.geminiClient.AnalyzeLyrics(ctx, lyrics)
	if err != nil {
		return fmt.Errorf("lyrics analysis failed: %w", err)
	}

	// タイトル生成（分析結果にタイトル案がなければ Gemini に再生成させる）
	title := analysis.SuggestedTitle
	if title == "" {
		title, err = u.geminiClient.GenerateTitle(ctx, lyrics, analysis.Mood)
		if err != nil {
			title = "無題"
		}
	}

	// Lyria で楽曲生成
	lyriaResp, err := u.lyriaClient.GenerateSong(ctx, &port.LyriaRequest{
		Lyrics:      lyrics,
		Mood:        analysis.Mood,
		Genre:       analysis.Genre,
		Tempo:       analysis.Tempo,
		DurationSec: u.defaultDurSec,
		Title:       title,
	})
	if err != nil {
		return fmt.Errorf("lyria generation failed: %w", err)
	}

	// Cloud Storage に音声ファイルをアップロード
	audioURL, err := u.songUploader.UploadSong(ctx, job.ChainID, lyriaResp.AudioData)
	if err != nil {
		return fmt.Errorf("storage upload failed: %w", err)
	}

	// DB に保存
	return u.lyriaJobRepo.CompleteJob(ctx, job.JobID, job.ChainID, repository.SaveSongInput{
		ID:          uuid.NewString(),
		Title:       title,
		AudioURL:    audioURL,
		DurationSec: lyriaResp.DurationSec,
		Mood:        analysis.Mood,
		Genre:       analysis.Genre,
	})
}
