package entity

type TrackInfo struct {
	ID         string
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
	AlbumName  *string
	DurationMs *int
}
