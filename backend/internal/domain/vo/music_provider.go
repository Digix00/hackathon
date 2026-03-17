package vo

import domainerrs "hackathon/internal/domain/errs"

// MusicProvider は音楽サービスのプロバイダー。
type MusicProvider string

const (
	MusicProviderSpotify    MusicProvider = "spotify"
	MusicProviderAppleMusic MusicProvider = "apple_music"
)

// ParseMusicProvider は文字列を MusicProvider に変換する。無効値の場合は BadRequest を返す。
func ParseMusicProvider(s string) (MusicProvider, error) {
	switch MusicProvider(s) {
	case MusicProviderSpotify, MusicProviderAppleMusic:
		return MusicProvider(s), nil
	}
	return "", domainerrs.BadRequest("invalid provider: " + s + ". must be spotify or apple_music")
}
