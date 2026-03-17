package request

// @name MusicCallbackQuery
type MusicCallbackQuery struct {
	Code  string `query:"code"`
	State string `query:"state"`
}
