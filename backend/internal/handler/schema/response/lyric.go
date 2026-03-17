package response

import "time"

// @name PostLyricResponse
// PostLyricResponse は歌詞投稿レスポンス。
type PostLyricResponse struct {
	LyricEntry LyricEntryItem `json:"lyric_entry"`
	Chain      LyricChainItem `json:"chain"`
}

// @name LyricEntryItem
// LyricEntryItem は歌詞エントリの基本情報。
type LyricEntryItem struct {
	ID          string    `json:"id"`
	ChainID     string    `json:"chain_id"`
	SequenceNum int       `json:"sequence_num"`
	Content     string    `json:"content"`
	CreatedAt   time.Time `json:"created_at"`
}

// @name LyricChainItem
// LyricChainItem は歌詞チェーンの基本情報。
type LyricChainItem struct {
	ID               string `json:"id"`
	ParticipantCount int    `json:"participant_count"`
	Threshold        int    `json:"threshold"`
	Status           string `json:"status" enums:"pending,generating,completed,failed"`
}

// @name LyricChainDetailResponse
// LyricChainDetailResponse はチェーン詳細レスポンス。
type LyricChainDetailResponse struct {
	Chain   LyricChainDetailItem     `json:"chain"`
	Entries []LyricEntryWithUserItem `json:"entries"`
	Song    *GeneratedSongItem       `json:"song,omitempty"`
}

// @name LyricChainDetailItem
// LyricChainDetailItem はチェーン詳細の Chain 部分。
type LyricChainDetailItem struct {
	ID               string `json:"id"`
	Status           string `json:"status" enums:"pending,generating,completed,failed"`
	ParticipantCount int    `json:"participant_count"`
	Threshold        int    `json:"threshold"`
}

// @name LyricEntryWithUserItem
// LyricEntryWithUserItem はユーザー情報付き歌詞エントリ。
type LyricEntryWithUserItem struct {
	SequenceNum int      `json:"sequence_num"`
	Content     string   `json:"content"`
	User        UserBrief `json:"user"`
}

// @name UserBrief
// UserBrief は最小限のユーザー情報。
type UserBrief struct {
	ID          string  `json:"id"`
	DisplayName string  `json:"display_name"`
	AvatarURL   *string `json:"avatar_url"`
}

// @name GeneratedSongItem
// GeneratedSongItem は生成楽曲情報。
type GeneratedSongItem struct {
	ID          string  `json:"id"`
	Title       *string `json:"title"`
	AudioURL    *string `json:"audio_url"`
	DurationSec *int    `json:"duration_sec"`
	Mood        *string `json:"mood"`
}
