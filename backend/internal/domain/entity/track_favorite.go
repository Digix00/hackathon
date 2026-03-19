package entity

import "time"

type TrackFavorite struct {
	ID        string
	UserID    string
	Track     *TrackInfo
	CreatedAt time.Time
}
