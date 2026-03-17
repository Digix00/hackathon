package entity

import (
	"time"

	"github.com/google/uuid"
)

// LyricEntry は歌詞チェーンへの1ユーザー分の投稿。
type LyricEntry struct {
	ID          string
	ChainID     string
	UserID      string
	EncounterID string
	Content     string
	SequenceNum int
	CreatedAt   time.Time
}

// NewLyricEntry は新規 LyricEntry を生成する。
func NewLyricEntry(chainID, userID, encounterID, content string, sequenceNum int) LyricEntry {
	return LyricEntry{
		ID:          uuid.NewString(),
		ChainID:     chainID,
		UserID:      userID,
		EncounterID: encounterID,
		Content:     content,
		SequenceNum: sequenceNum,
	}
}
