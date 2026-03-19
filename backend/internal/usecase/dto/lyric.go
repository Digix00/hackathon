package dto

import "time"

type SubmitLyricInput struct {
	EncounterID string
	Content     string
}

type LyricEntryDTO struct {
	ID          string
	ChainID     string
	SequenceNum int
	Content     string
	CreatedAt   time.Time
}

type LyricChainDTO struct {
	ID               string
	ParticipantCount int
	Threshold        int
	Status           string
}

type SubmitLyricResult struct {
	Entry LyricEntryDTO
	Chain LyricChainDTO
}

type LyricEntryWithUserDTO struct {
	SequenceNum int
	Content     string
	UserID      string
	DisplayName *string
	AvatarURL   *string
}

type GeneratedSongDTO struct {
	ID          string
	Title       *string
	AudioURL    *string
	DurationSec *int
	Mood        *string
}

type ChainDetailDTO struct {
	ID               string
	Status           string
	ParticipantCount int
	Threshold        int
	CreatedAt        time.Time
	CompletedAt      *time.Time
}

type ChainDetailResult struct {
	Chain   ChainDetailDTO
	Entries []LyricEntryWithUserDTO
	Song    *GeneratedSongDTO
}

type UserSongDTO struct {
	ID               string
	Title            *string
	AudioURL         *string
	ParticipantCount int
	MyLyric          string
	GeneratedAt      *time.Time
}

type ListUserSongsResult struct {
	Songs      []UserSongDTO
	NextCursor *string
	HasMore    bool
}
