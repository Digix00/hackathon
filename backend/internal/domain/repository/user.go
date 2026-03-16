package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/vo"
)

// CreateUserParams はユーザー作成に必要なパラメータをまとめた構造体。
type CreateUserParams struct {
	ID             string
	AuthProvider   string
	ProviderUserID string
	DisplayName    string
	Bio            *string
	Birthdate      *time.Time
	AgeVisibility  vo.AgeVisibility
	PrefectureID   *string
	Sex            vo.Sex
	AvatarURL      *string
	CreateSettings bool
}

// UpdateUserParams はユーザー更新の変更意図をまとめた構造体。ポインタ型フィールドが nil の場合は変更なし。
type UpdateUserParams struct {
	DisplayName   *string
	Bio           *string
	BirthdateSet  bool
	Birthdate     *time.Time
	AgeVisibility *vo.AgeVisibility
	PrefectureID  *string
	Sex           *vo.Sex
	AvatarURLSet  bool
	AvatarURL     *string
}

type UserRepository interface {
	FindByAuthProviderAndProviderUserID(ctx context.Context, authProvider, providerUserID string) (entity.User, error)
	FindByID(ctx context.Context, id string) (entity.User, error)
	Create(ctx context.Context, params CreateUserParams) (entity.User, error)
	Update(ctx context.Context, userID string, params UpdateUserParams) (entity.User, error)
	DeleteWithCleanup(ctx context.Context, userID string) error
}
