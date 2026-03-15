package model

import (
	"time"

	"gorm.io/gorm"
)

type LyricChain struct {
	ID               string         `gorm:"primaryKey"`
	Status           string         `gorm:"not null;default:pending;index"` // 'pending' | 'generating' | 'completed' | 'failed'
	ParticipantCount int            `gorm:"not null;default:0"`
	Threshold        int            `gorm:"not null;default:4"`
	CreatedAt        time.Time      `gorm:"not null;autoCreateTime;index"`
	CompletedAt      *time.Time
	DeletedAt        gorm.DeletedAt `gorm:"index"` // #1 MUST

	Entries       []LyricEntry   `gorm:"foreignKey:ChainID"`
	GeneratedSong *GeneratedSong `gorm:"foreignKey:ChainID"`
}

type LyricEntry struct {
	ID          string         `gorm:"primaryKey"`
	// uq_lyric_entries_user: (chain_id, user_id) — 同一ユーザーの重複参加防止（model タグで定義）
	// uq_lyric_entries_seq:  (chain_id, sequence_num) WHERE deleted_at IS NULL
	//   → ソフトデリート済みエントリが UNIQUE 違反を起こさないよう部分インデックスが必要なため
	//     migrate.go の applyManualConstraints で定義する
	ChainID     string         `gorm:"not null;index"`
	UserID      string         `gorm:"not null;index"`
	EncounterID string         `gorm:"not null;index"`
	Content     string         `gorm:"not null"`
	SequenceNum int            `gorm:"not null"`
	CreatedAt   time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt   gorm.DeletedAt `gorm:"index"`

	// content 長さ制約は migrate.go の applyManualConstraints で定義
}

type GeneratedSong struct {
	ID          string         `gorm:"primaryKey"`
	ChainID     string         `gorm:"not null;uniqueIndex"`
	Title       *string
	AudioURL    *string
	DurationSec *int
	Mood        *string
	Genre       *string
	Status      string         `gorm:"not null;default:processing;index"` // 'processing' | 'completed' | 'failed'
	GeneratedAt *time.Time     `gorm:"index"`
	CreatedAt   time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt   gorm.DeletedAt `gorm:"index"` // #1 MUST
}

type SongLike struct {
	ID        string         `gorm:"primaryKey"`
	SongID    string         `gorm:"not null;index"`
	UserID    string         `gorm:"not null;index"`
	CreatedAt time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`
	// uq_song_likes (song_id, user_id) WHERE deleted_at IS NULL は migrate.go で定義
}

type OutboxLyriaJob struct {
	ID           string     `gorm:"primaryKey"`
	ChainID      string     `gorm:"not null;index"`
	Status       string     `gorm:"not null;default:pending;index"` // 'pending' | 'processing' | 'completed' | 'failed'
	RetryCount   int        `gorm:"not null;default:0"`
	ErrorMessage *string
	CreatedAt    time.Time  `gorm:"not null;autoCreateTime;index"`
	ProcessedAt  *time.Time
}
