package response

type ListUserSongsResponse struct {
	Songs      []UserSong     `json:"songs"`
	Pagination SongPagination `json:"pagination"`
}

type UserSong struct {
	ID               string  `json:"id"`
	Title            *string `json:"title,omitempty"`
	AudioURL         *string `json:"audio_url,omitempty"`
	ChainID          string  `json:"chain_id"`
	DurationSec      *int    `json:"duration_sec,omitempty"`
	Mood             *string `json:"mood,omitempty"`
	ParticipantCount int     `json:"participant_count"`
	MyLyric          string  `json:"my_lyric"`
	GeneratedAt      *string `json:"generated_at,omitempty"`
}

type SongPagination struct {
	NextCursor *string `json:"next_cursor"`
	HasMore    bool    `json:"has_more"`
}

type LikeSongResponse struct {
	Liked bool `json:"liked"`
}
