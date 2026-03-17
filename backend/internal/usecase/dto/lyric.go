package dto

import "time"

// LyricEntryDTO は歌詞エントリのDTO。
type LyricEntryDTO struct {
	ID          string
	ChainID     string
	SequenceNum int
	Content     string
	CreatedAt   time.Time
}

// LyricChainDTO は歌詞チェーンのDTO。
type LyricChainDTO struct {
	ID               string
	Status           string
	ParticipantCount int
	Threshold        int
}

// PostLyricResultDTO は歌詞投稿結果のDTO。
type PostLyricResultDTO struct {
	Entry LyricEntryDTO
	Chain LyricChainDTO
}

// LyricChainDetailDTO は歌詞チェーン詳細のDTO（エントリ + 生成楽曲含む）。
type LyricChainDetailDTO struct {
	Chain   LyricChainDTO
	Entries []LyricEntryWithUserDTO
	Song    *GeneratedSongDTO // status == "completed" のときのみ
}

// LyricEntryWithUserDTO はユーザー情報付き歌詞エントリ。
type LyricEntryWithUserDTO struct {
	SequenceNum int
	Content     string
	UserID      string
	DisplayName string
	AvatarURL   *string
}

// GeneratedSongDTO は生成楽曲のDTO。
type GeneratedSongDTO struct {
	ID          string
	Title       *string
	AudioURL    *string
	DurationSec *int
	Mood        *string
}
