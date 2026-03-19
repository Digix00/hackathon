package entity

import (
	"time"

	"github.com/google/uuid"
)

type LyricChain struct {
	ID               string
	Status           string
	ParticipantCount int
	Threshold        int
	CreatedAt        time.Time
	CompletedAt      *time.Time
}

type LyricEntry struct {
	ID          string
	ChainID     string
	UserID      string
	EncounterID string
	Content     string
	SequenceNum int
	CreatedAt   time.Time
}

type GeneratedSong struct {
	ID          string
	ChainID     string
	Title       *string
	AudioURL    *string
	DurationSec *int
	Mood        *string
	Genre       *string
	Status      string
	GeneratedAt *time.Time
	CreatedAt   time.Time
}

type SongLike struct {
	ID        string
	SongID    string
	UserID    string
	CreatedAt time.Time
}

func NewLyricChain() LyricChain {
	return LyricChain{
		ID:               uuid.NewString(),
		Status:           "pending",
		ParticipantCount: 0,
		Threshold:        4,
		CreatedAt:        time.Now().UTC(),
	}
}

func NewSongLike(songID, userID string) SongLike {
	return SongLike{
		ID:        uuid.NewString(),
		SongID:    songID,
		UserID:    userID,
		CreatedAt: time.Now().UTC(),
	}
}
