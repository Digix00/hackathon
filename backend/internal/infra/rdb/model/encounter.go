package model

import (
	"time"

	"gorm.io/gorm"
)

type Encounter struct {
	ID            string         `gorm:"primaryKey"`
	UserID1       string         `gorm:"not null;index"`
	UserID2       string         `gorm:"not null;index"`
	EncounteredAt time.Time      `gorm:"not null;index"`
	EncounterType string         `gorm:"not null"` // 'ble' | 'location'
	Latitude      *float64
	Longitude     *float64
	CreatedAt     time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt     gorm.DeletedAt `gorm:"index"` // #1 MUST

	// CHECK (user_id_1 < user_id_2) は migrate.go の applyManualConstraints で定義
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
	DeletedAt       gorm.DeletedAt `gorm:"index"` // #1 MUST
}

type Report struct {
	ID              string         `gorm:"primaryKey"`
	ReporterUserID  string         `gorm:"not null"`
	ReportedUserID  string         `gorm:"not null;index"`
	ReportType      string         `gorm:"not null"` // 'user' | 'comment'
	TargetCommentID *string        `gorm:"index"`
	Reason          string         `gorm:"not null"`
	CreatedAt       time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt       gorm.DeletedAt `gorm:"index"` // #1 MUST

	// CHECK 制約・部分 UNIQUE インデックスは migrate.go の applyManualConstraints で定義
}

type Block struct {
	ID            string         `gorm:"primaryKey"`
	BlockerUserID string         `gorm:"not null;index"`
	BlockedUserID string         `gorm:"not null;index"`
	CreatedAt     time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt     gorm.DeletedAt `gorm:"index"`
	// uq_blocks (blocker_user_id, blocked_user_id) WHERE deleted_at IS NULL は migrate.go で定義
}

type Mute struct {
	ID           string         `gorm:"primaryKey"`
	UserID       string         `gorm:"not null;index"`
	TargetUserID string         `gorm:"not null;index"`
	CreatedAt    time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt    gorm.DeletedAt `gorm:"index"`
	// uq_mutes (user_id, target_user_id) WHERE deleted_at IS NULL は migrate.go で定義
}

type OutboxNotification struct {
	ID          string     `gorm:"primaryKey"`
	UserID      string     `gorm:"not null;index"`
	EncounterID string     `gorm:"not null"`
	Status      string     `gorm:"not null;default:pending;index"` // 'pending' | 'sent' | 'failed'
	RetryCount  int        `gorm:"not null;default:0"`
	CreatedAt   time.Time  `gorm:"not null;autoCreateTime;index"`
	ProcessedAt *time.Time
}
