package dto

import "time"

// UserDTO は認証済みユーザー自身のプロフィール取得レスポンス用 DTO。
type UserDTO struct {
	ID            string
	DisplayName   string
	AvatarURL     *string
	Bio           *string
	Birthdate     *string // formatted as YYYY-MM-DD
	AgeVisibility string
	PrefectureID  *string
	Sex           string
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

// PublicUserDTO は他ユーザーのプロフィール閲覧レスポンス用 DTO。
type PublicUserDTO struct {
	ID             string
	DisplayName    string
	AvatarURL      *string
	Bio            *string
	Birthplace     *string // 都道府県名
	AgeRange       *string // 生年月日と公開設定から算出
	EncounterCount int64
	SharedTrack    *TrackInfoDTO
	UpdatedAt      time.Time
}

// TrackInfoDTO は公開プロフィールに表示する共有トラックの最小情報を保持する DTO。
type TrackInfoDTO struct {
	ID         string
	Title      string
	ArtistName string
	ArtworkURL *string
	PreviewURL *string
}

// CreateUserInput はユーザー作成時の入力データを保持する。
// AgeVisibility と Sex は省略可能で、nil の場合はデフォルト値（hidden / no-answer）が適用される。
type CreateUserInput struct {
	DisplayName   string
	Bio           *string
	Birthdate     *time.Time
	AgeVisibility *string
	PrefectureID  *string
	Sex           *string
	AvatarURL     *string
}

// UpdateUserInput はユーザー更新の変更意図を保持する。ポインタ型フィールドが nil の場合は変更なし。
type UpdateUserInput struct {
	DisplayName   *string
	Bio           *string
	BirthdateSet  bool
	Birthdate     *time.Time
	AgeVisibility *string
	PrefectureID  *string
	Sex           *string
	AvatarURLSet  bool
	AvatarURL     *string // nil + set=アバター削除、URL + set=新しいアバター URL
}
