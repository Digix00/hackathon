package usecase

import (
	"context"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	usecasedto "hackathon/internal/usecase/dto"
)

type CommentUsecase interface {
	CreateComment(ctx context.Context, authUID string, encounterID string, content string) (usecasedto.CommentDTO, error)
	ListComments(ctx context.Context, authUID string, encounterID string, limit int, cursor string) (usecasedto.ListCommentsOutput, error)
	DeleteComment(ctx context.Context, authUID string, commentID string) error
}

type commentUsecase struct {
	userRepo      repository.UserRepository
	commentRepo   repository.CommentRepository
	encounterRepo repository.EncounterRepository
}

func NewCommentUsecase(
	userRepo repository.UserRepository,
	commentRepo repository.CommentRepository,
	encounterRepo repository.EncounterRepository,
) CommentUsecase {
	return &commentUsecase{
		userRepo:      userRepo,
		commentRepo:   commentRepo,
		encounterRepo: encounterRepo,
	}
}

func (u *commentUsecase) CreateComment(ctx context.Context, authUID string, encounterID string, content string) (usecasedto.CommentDTO, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.CommentDTO{}, err
	}

	exists, err := u.encounterRepo.ExistsByIDAndParticipant(ctx, encounterID, user.ID)
	if err != nil {
		return usecasedto.CommentDTO{}, err
	}
	if !exists {
		return usecasedto.CommentDTO{}, domainerrs.NotFound("encounter not found")
	}

	comment := entity.NewComment(encounterID, user, content)
	if err := u.commentRepo.Create(ctx, comment); err != nil {
		return usecasedto.CommentDTO{}, err
	}

	return commentToDTO(comment), nil
}

func (u *commentUsecase) ListComments(ctx context.Context, authUID string, encounterID string, limit int, cursor string) (usecasedto.ListCommentsOutput, error) {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return usecasedto.ListCommentsOutput{}, err
	}

	exists, err := u.encounterRepo.ExistsByIDAndParticipant(ctx, encounterID, user.ID)
	if err != nil {
		return usecasedto.ListCommentsOutput{}, err
	}
	if !exists {
		return usecasedto.ListCommentsOutput{}, domainerrs.NotFound("encounter not found")
	}

	parsedCursor, err := parseCommentCursor(cursor)
	if err != nil {
		return usecasedto.ListCommentsOutput{}, err
	}

	comments, nextCursorVal, hasMore, err := u.commentRepo.ListByEncounterID(ctx, encounterID, limit, parsedCursor)
	if err != nil {
		return usecasedto.ListCommentsOutput{}, err
	}

	nextCursor, err := encodeCommentCursor(nextCursorVal)
	if err != nil {
		return usecasedto.ListCommentsOutput{}, err
	}

	dtos := make([]usecasedto.CommentDTO, len(comments))
	for i, c := range comments {
		dtos[i] = commentToDTO(c)
	}

	return usecasedto.ListCommentsOutput{
		Comments:   dtos,
		NextCursor: nextCursor,
		HasMore:    hasMore,
	}, nil
}

func (u *commentUsecase) DeleteComment(ctx context.Context, authUID string, commentID string) error {
	user, err := u.userRepo.FindByAuthProviderAndProviderUserID(ctx, firebaseProvider, authUID)
	if err != nil {
		return err
	}

	comment, err := u.commentRepo.FindByID(ctx, commentID)
	if err != nil {
		return err
	}

	if comment.User.ID != user.ID {
		return domainerrs.Forbidden("you can only delete your own comments")
	}

	return u.commentRepo.SoftDelete(ctx, commentID)
}

func commentToDTO(c entity.Comment) usecasedto.CommentDTO {
	return usecasedto.CommentDTO{
		ID:            c.ID,
		EncounterID:   c.EncounterID,
		UserID:        c.User.ID,
		UserName:      c.User.DisplayName,
		UserAvatarURL: c.User.AvatarURL,
		Content:       c.Content,
		CreatedAt:     c.CreatedAt,
	}
}
