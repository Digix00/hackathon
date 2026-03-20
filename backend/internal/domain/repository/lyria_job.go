package repository

import "context"

// OutboxLyriaJobDetail は処理対象のジョブとチェーンの歌詞をまとめた構造体
type OutboxLyriaJobDetail struct {
	JobID   string
	ChainID string
	// Lyrics は sequenceNum 昇順の歌詞エントリ一覧
	Lyrics []string
}

// SaveSongInput は GeneratedSong の保存に必要な入力データ
type SaveSongInput struct {
	ID          string
	Title       string
	AudioURL    string
	DurationSec int
	Mood        string
	Genre       string
}

// LyriaJobRepository は OutboxLyriaJob の操作を担当するリポジトリインターフェース
type LyriaJobRepository interface {
	// ClaimPendingJobs は pending 状態のジョブを最大 limit 件取得し、processing に遷移させる
	ClaimPendingJobs(ctx context.Context, limit int) ([]OutboxLyriaJobDetail, error)

	// CompleteJob はジョブを completed に更新し、生成楽曲を保存してチェーンを completed に更新する
	CompleteJob(ctx context.Context, jobID, chainID string, song SaveSongInput) error

	// FailJob はジョブ失敗を記録する。permanent=true またはリトライ回数が閾値に達した場合は
	// ジョブを failed に遷移させ、関連する LyricChain も failed に更新する。
	// それ以外はリトライのため pending に戻す。
	FailJob(ctx context.Context, jobID string, errMsg string, permanent bool) error
}
