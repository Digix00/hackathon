package vo

// OutboxLyriaJobStatus は Lyria 生成ジョブの状態。
type OutboxLyriaJobStatus string

const (
	OutboxLyriaJobStatusPending    OutboxLyriaJobStatus = "pending"
	OutboxLyriaJobStatusProcessing OutboxLyriaJobStatus = "processing"
	OutboxLyriaJobStatusCompleted  OutboxLyriaJobStatus = "completed"
	OutboxLyriaJobStatusFailed     OutboxLyriaJobStatus = "failed"
)
