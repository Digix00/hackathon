package repository

import (
	"context"

	"hackathon/internal/domain/entity"
)

// LyricEntryWithUser pairs a lyric entry with its author.
type LyricEntryWithUser struct {
	Entry entity.LyricEntry
	User  entity.User
}

// ChainDetailResult is returned by GetChainWithDetails.
type ChainDetailResult struct {
	Chain   entity.LyricChain
	Entries []LyricEntryWithUser
	Song    *entity.GeneratedSong
}

// UserSongResult is one song in the user's participated-songs list.
type UserSongResult struct {
	Song             entity.GeneratedSong
	ParticipantCount int
	MyLyric          string
}

// SubmitLyricResult is the result of a successful lyric submission.
type SubmitLyricResult struct {
	Entry entity.LyricEntry
	Chain entity.LyricChain
}

// LyricRepository handles all lyric chain / entry / song / like operations.
type LyricRepository interface {
	SubmitEntry(ctx context.Context, userID, encounterID, content string) (SubmitLyricResult, error)
	GetChainWithDetails(ctx context.Context, chainID string) (ChainDetailResult, error)
	FindSongByID(ctx context.Context, songID string) (entity.GeneratedSong, error)
	ListUserSongs(ctx context.Context, userID string, cursor string, limit int) ([]UserSongResult, string, bool, error)
	CreateSongLike(ctx context.Context, like entity.SongLike) error
	DeleteSongLike(ctx context.Context, userID, songID string) error
	ExistsSongLike(ctx context.Context, userID, songID string) (bool, error)
}
