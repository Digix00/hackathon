package vo

import domainerrs "hackathon/internal/domain/errs"

// OutboxLyriaJobStatus は Lyria 生成ジョブの状態。
type OutboxLyriaJobStatus string

const (
	OutboxLyriaJobStatusPending    OutboxLyriaJobStatus = "pending"
	OutboxLyriaJobStatusProcessing OutboxLyriaJobStatus = "processing"
	OutboxLyriaJobStatusCompleted  OutboxLyriaJobStatus = "completed"
	OutboxLyriaJobStatusFailed     OutboxLyriaJobStatus = "failed"
)

// NewOutboxLyriaJobStatus は文字列を OutboxLyriaJobStatus に変換する。無効値の場合は BadRequest を返す。
func NewOutboxLyriaJobStatus(s string) (OutboxLyriaJobStatus, error) {
	switch OutboxLyriaJobStatus(s) {
	case OutboxLyriaJobStatusPending, OutboxLyriaJobStatusProcessing, OutboxLyriaJobStatusCompleted, OutboxLyriaJobStatusFailed:
		return OutboxLyriaJobStatus(s), nil
	}
	return "", domainerrs.BadRequest("invalid outbox_lyria_job_status: " + s)
}
