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
	ChainID     string         `gorm:"not null;index;uniqueIndex:uq_lyric_entries_seq,where:deleted_at IS NULL;uniqueIndex:uq_lyric_entries_user,where:deleted_at IS NULL"`
	UserID      string         `gorm:"not null;index;uniqueIndex:uq_lyric_entries_user,where:deleted_at IS NULL"`
	EncounterID string         `gorm:"not null;index"`
	Content     string         `gorm:"not null;check:chk_lyric_entries_len,char_length(content) <= 100"`
	SequenceNum int            `gorm:"not null;uniqueIndex:uq_lyric_entries_seq,where:deleted_at IS NULL"`
	CreatedAt   time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt   gorm.DeletedAt `gorm:"index"`
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
	SongID    string         `gorm:"not null;index;uniqueIndex:uq_song_likes,where:deleted_at IS NULL"`
	UserID    string         `gorm:"not null;index;uniqueIndex:uq_song_likes,where:deleted_at IS NULL"`
	CreatedAt time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"`
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
