package response

type SubmitLyricResponse struct {
	LyricEntry SubmitLyricEntry `json:"lyric_entry"`
	Chain      SubmitLyricChain `json:"chain"`
}

type SubmitLyricEntry struct {
	ID          string `json:"id"`
	ChainID     string `json:"chain_id"`
	SequenceNum int    `json:"sequence_num"`
	Content     string `json:"content"`
	CreatedAt   string `json:"created_at"`
}

type SubmitLyricChain struct {
	ID               string `json:"id"`
	ParticipantCount int    `json:"participant_count"`
	Threshold        int    `json:"threshold"`
	Status           string `json:"status"`
}

type ChainDetailResponse struct {
	Chain   ChainDetail   `json:"chain"`
	Entries []EntryDetail `json:"entries"`
	Song    *SongDetail   `json:"song,omitempty"`
}

type ChainDetail struct {
	ID               string  `json:"id"`
	Status           string  `json:"status"`
	ParticipantCount int     `json:"participant_count"`
	Threshold        int     `json:"threshold"`
	CreatedAt        string  `json:"created_at"`
	CompletedAt      *string `json:"completed_at,omitempty"`
}

type EntryDetail struct {
	SequenceNum int       `json:"sequence_num"`
	Content     string    `json:"content"`
	User        EntryUser `json:"user"`
}

type EntryUser struct {
	ID          string  `json:"id"`
	DisplayName string  `json:"display_name"`
	AvatarURL   *string `json:"avatar_url,omitempty"`
}

type SongDetail struct {
	ID          string  `json:"id"`
	Title       *string `json:"title,omitempty"`
	AudioURL    *string `json:"audio_url,omitempty"`
	DurationSec *int    `json:"duration_sec,omitempty"`
	Mood        *string `json:"mood,omitempty"`
}
