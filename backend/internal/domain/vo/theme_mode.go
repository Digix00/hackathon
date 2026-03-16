package vo

import domainerrs "hackathon/internal/domain/errs"

// ThemeMode はUIテーマモードを表す値オブジェクト。
type ThemeMode string

const (
	ThemeModeLight  ThemeMode = "light"
	ThemeModeDark   ThemeMode = "dark"
	ThemeModeSystem ThemeMode = "system"
)

// ParseThemeMode は文字列をThemeModeにパースする。
// 不正な値の場合はドメインエラーを返す。
func ParseThemeMode(s string) (ThemeMode, error) {
	switch ThemeMode(s) {
	case ThemeModeLight, ThemeModeDark, ThemeModeSystem:
		return ThemeMode(s), nil
	}
	return "", domainerrs.BadRequest("theme_mode is invalid")
}
