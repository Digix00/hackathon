package util

// ApplyIfSet はsrcがnilでない場合のみdstに値を書き込む。
// PATCHリクエストの部分更新パターンで使用する。
func ApplyIfSet[T any](dst *T, src *T) {
	if src != nil {
		*dst = *src
	}
}
