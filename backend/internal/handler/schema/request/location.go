package request

// @name PostLocationRequest
type PostLocationRequest struct {
	Lat        *float64 `json:"lat"`
	Lng        *float64 `json:"lng"`
	AccuracyM  float64  `json:"accuracy_m"`
	RecordedAt string   `json:"recorded_at"`
}
