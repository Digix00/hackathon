package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/vo"
)

// CreateUserParams holds all data needed to create a new user
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

// UpdateUserParams holds change intentions for a user update
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
