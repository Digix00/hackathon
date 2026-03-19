package response

type ListUserSongsResponse struct {
	Songs      []UserSong     `json:"songs"`
	Pagination SongPagination `json:"pagination"`
}

type UserSong struct {
	ID               string  `json:"id"`
	Title            *string `json:"title,omitempty"`
	AudioURL         *string `json:"audio_url,omitempty"`
	ParticipantCount int     `json:"participant_count"`
	MyLyric          string  `json:"my_lyric"`
	GeneratedAt      *string `json:"generated_at,omitempty"`
}

type SongPagination struct {
	NextCursor *string `json:"next_cursor"`
	HasMore    bool    `json:"has_more"`
}

type LikeSongResponse struct {
	Like LikeSongDetail `json:"like"`
}

type LikeSongDetail struct {
	SongID    *string `json:"song_id,omitempty"`
	Liked     bool    `json:"liked"`
	CreatedAt *string `json:"created_at,omitempty"`
}
