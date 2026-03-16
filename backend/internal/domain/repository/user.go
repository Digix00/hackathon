package repository

import (
	"context"
	"time"

	"hackathon/internal/domain/entity"
)

// CreateUserParams holds all data needed to create a new user (with optional avatar file and settings)
type CreateUserParams struct {
	ID             string
	AuthProvider   string
	ProviderUserID string
	DisplayName    string
	Bio            *string
	Birthdate      *time.Time
	AgeVisibility  string
	PrefectureID   *string
	Sex            string
	AvatarURL      *string // if non-nil, create a File record and link it
	CreateSettings bool    // if true, create UserSettings for the new user
}

// UpdateUserParams holds change intentions for a user update
type UpdateUserParams struct {
	DisplayName   *string
	Bio           *string
	BirthdateSet  bool
	Birthdate     *time.Time
	AgeVisibility *string
	PrefectureID  *string
	Sex           *string
	AvatarURLSet  bool
	AvatarURL     *string // nil+set=clear, URL+set=new file
}

type UserRepository interface {
	FindByAuthProviderAndProviderUserID(ctx context.Context, authProvider, providerUserID string) (entity.User, error)
	FindByID(ctx context.Context, id string) (entity.User, error)
	Create(ctx context.Context, params CreateUserParams) (entity.User, error)
	Update(ctx context.Context, userID string, params UpdateUserParams) (entity.User, error)
	DeleteWithCleanup(ctx context.Context, userID string) error
}
