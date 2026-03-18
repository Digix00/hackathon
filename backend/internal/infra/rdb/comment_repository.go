package rdb

import (
	"context"
	"encoding/base64"
	"time"

	"gorm.io/gorm"

	"hackathon/internal/domain/entity"
	domainerrs "hackathon/internal/domain/errs"
	"hackathon/internal/domain/repository"
	"hackathon/internal/infra/rdb/model"
)

type commentRepository struct {
	db *gorm.DB
}

func NewCommentRepository(db *gorm.DB) repository.CommentRepository {
	return &commentRepository{db: db}
}

type commentRow struct {
	ID              string
	EncounterID     string
	CommenterUserID string
	Content         string
	CreatedAt       time.Time
	UserName        *string
	UserAvatarPath  *string
}

func (r *commentRepository) Create(ctx context.Context, comment entity.Comment) error {
	m := model.Comment{
		ID:              comment.ID,
		EncounterID:     comment.EncounterID,
		CommenterUserID: comment.User.ID,
		Content:         comment.Content,
		CreatedAt:       comment.CreatedAt,
	}
	return r.db.WithContext(ctx).Create(&m).Error
}

func (r *commentRepository) FindByID(ctx context.Context, id string) (entity.Comment, error) {
	var row commentRow
	err := r.db.WithContext(ctx).
		Table("comments").
		Select("comments.id, comments.encounter_id, comments.commenter_user_id, comments.content, comments.created_at, users.name as user_name, files.file_path as user_avatar_path").
		Joins("LEFT JOIN users ON users.id = comments.commenter_user_id AND users.deleted_at IS NULL").
		Joins("LEFT JOIN files ON files.id = users.avatar_file_id AND files.deleted_at IS NULL").
		Where("comments.id = ? AND comments.deleted_at IS NULL", id).
		Scan(&row).Error
	if err != nil {
		return entity.Comment{}, err
	}
	if row.ID == "" {
		return entity.Comment{}, domainerrs.NotFound("comment not found")
	}
	return rowToComment(row), nil
}

func (r *commentRepository) ListByEncounterID(ctx context.Context, encounterID string, limit int, cursor string) ([]entity.Comment, string, bool, error) {
	q := r.db.WithContext(ctx).
		Table("comments").
		Select("comments.id, comments.encounter_id, comments.commenter_user_id, comments.content, comments.created_at, users.name as user_name, files.file_path as user_avatar_path").
		Joins("LEFT JOIN users ON users.id = comments.commenter_user_id AND users.deleted_at IS NULL").
		Joins("LEFT JOIN files ON files.id = users.avatar_file_id AND files.deleted_at IS NULL").
		Where("comments.encounter_id = ? AND comments.deleted_at IS NULL", encounterID).
		Order("comments.created_at DESC")

	if cursor != "" {
		if t, err := decodeCursor(cursor); err == nil {
			q = q.Where("comments.created_at < ?", t)
		}
	}

	var rows []commentRow
	if err := q.Limit(limit + 1).Scan(&rows).Error; err != nil {
		return nil, "", false, err
	}

	hasMore := len(rows) > limit
	if hasMore {
		rows = rows[:limit]
	}

	comments := make([]entity.Comment, len(rows))
	for i, row := range rows {
		comments[i] = rowToComment(row)
	}

	var nextCursor string
	if hasMore && len(comments) > 0 {
		nextCursor = encodeCursor(comments[len(comments)-1].CreatedAt)
	}

	return comments, nextCursor, hasMore, nil
}

func (r *commentRepository) SoftDelete(ctx context.Context, id string) error {
	return r.db.WithContext(ctx).
		Where("id = ?", id).
		Delete(&model.Comment{}).Error
}

func rowToComment(row commentRow) entity.Comment {
	displayName := ""
	if row.UserName != nil {
		displayName = *row.UserName
	}
	return entity.Comment{
		ID:          row.ID,
		EncounterID: row.EncounterID,
		User: entity.CommentUser{
			ID:          row.CommenterUserID,
			DisplayName: displayName,
			AvatarURL:   row.UserAvatarPath,
		},
		Content:   row.Content,
		CreatedAt: row.CreatedAt,
	}
}

func encodeCursor(t time.Time) string {
	return base64.StdEncoding.EncodeToString([]byte(t.UTC().Format(time.RFC3339Nano)))
}

func decodeCursor(cursor string) (time.Time, error) {
	b, err := base64.StdEncoding.DecodeString(cursor)
	if err != nil {
		return time.Time{}, err
	}
	return time.Parse(time.RFC3339Nano, string(b))
}
