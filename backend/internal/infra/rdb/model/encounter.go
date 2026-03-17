package model

import (
	"time"

	"gorm.io/gorm"
)

type Encounter struct {
	ID            string    `gorm:"primaryKey"`
	UserID1       string    `gorm:"not null;index;check:chk_encounters_user_order,user_id1 < user_id2"`
	UserID2       string    `gorm:"not null;index"`
	EncounteredAt time.Time `gorm:"not null;index"`
	EncounterType string    `gorm:"not null"` // 'ble' | 'location'
	Latitude      *float64
	Longitude     *float64
	CreatedAt     time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt     gorm.DeletedAt `gorm:"index"`

	User1 *User `gorm:"foreignKey:UserID1"`
	User2 *User `gorm:"foreignKey:UserID2"`
}

type EncounterRead struct {
	ID          string    `gorm:"primaryKey"`
	UserID      string    `gorm:"not null;uniqueIndex:uq_encounter_reads;index"`
	EncounterID string    `gorm:"not null;uniqueIndex:uq_encounter_reads;index"`
	ReadAt      time.Time `gorm:"not null;autoCreateTime"`
}

type DailyEncounterCount struct {
	ID        string    `gorm:"primaryKey"`
	UserID    string    `gorm:"not null;uniqueIndex:uq_daily_encounter_counts"`
	Date      time.Time `gorm:"not null;uniqueIndex:uq_daily_encounter_counts;type:date"`
	Count     int       `gorm:"not null;default:0"`
	CreatedAt time.Time `gorm:"not null;autoCreateTime"`
	UpdatedAt time.Time `gorm:"not null;autoUpdateTime"`
}

type Comment struct {
	ID              string         `gorm:"primaryKey"`
	EncounterID     string         `gorm:"not null;index"`
	CommenterUserID string         `gorm:"not null;index"`
	Content         string         `gorm:"not null"`
	CreatedAt       time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt       gorm.DeletedAt `gorm:"index"`
}

type Report struct {
	ID              string         `gorm:"primaryKey"`
	ReporterUserID  string         `gorm:"not null;uniqueIndex:uq_reports_comment,where:report_type = 'comment' AND deleted_at IS NULL;uniqueIndex:uq_reports_user,where:report_type = 'user' AND deleted_at IS NULL"`
	ReportedUserID  string         `gorm:"not null;index;uniqueIndex:uq_reports_comment,where:report_type = 'comment' AND deleted_at IS NULL;uniqueIndex:uq_reports_user,where:report_type = 'user' AND deleted_at IS NULL"`
	ReportType      string         `gorm:"not null;check:chk_reports_type,(report_type = 'comment' AND target_comment_id IS NOT NULL) OR (report_type = 'user' AND target_comment_id IS NULL);uniqueIndex:uq_reports_comment,where:report_type = 'comment' AND deleted_at IS NULL;uniqueIndex:uq_reports_user,where:report_type = 'user' AND deleted_at IS NULL"` // 'user' | 'comment'
	TargetCommentID *string        `gorm:"index;uniqueIndex:uq_reports_comment,where:report_type = 'comment' AND deleted_at IS NULL"`
	Reason          string         `gorm:"not null"`
	CreatedAt       time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt       gorm.DeletedAt `gorm:"index"`
}

type Block struct {
	ID            string         `gorm:"primaryKey"`
	BlockerUserID string         `gorm:"not null;index;uniqueIndex:uq_blocks,where:deleted_at IS NULL"`
	BlockedUserID string         `gorm:"not null;index;uniqueIndex:uq_blocks,where:deleted_at IS NULL"`
	CreatedAt     time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt     gorm.DeletedAt `gorm:"index"`
}

type Mute struct {
	ID           string         `gorm:"primaryKey"`
	UserID       string         `gorm:"not null;index;uniqueIndex:uq_mutes,where:deleted_at IS NULL"`
	TargetUserID string         `gorm:"not null;index;uniqueIndex:uq_mutes,where:deleted_at IS NULL"`
	CreatedAt    time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt    gorm.DeletedAt `gorm:"index"`
}

type OutboxNotification struct {
	ID          string     `gorm:"primaryKey"`
	UserID      string     `gorm:"not null;index"`
	EncounterID string     `gorm:"not null"`
	Status      string     `gorm:"not null;default:pending;index"` // 'pending' | 'sent' | 'failed'
	RetryCount  int        `gorm:"not null;default:0"`
	CreatedAt   time.Time  `gorm:"not null;autoCreateTime;index"`
	ProcessedAt *time.Time
	ReadAt      *time.Time
}
