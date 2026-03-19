package repository

import (
	"context"
	"time"
)

// NearbyUserInfo は位置情報が最近更新されたユーザーの情報。
type NearbyUserInfo struct {
	UserID            string
	Latitude          float64
	Longitude         float64
	DetectionDistance int
}

type UserLocationRepository interface {
	// Upsert はユーザーの現在位置を登録・更新する。
	Upsert(ctx context.Context, id, userID string, lat, lng float64) error

	// FindRecentlyActive は since 以降に位置を更新した requesterID 以外のユーザーを返す。
	// 各ユーザーの detection_distance を user_settings から取得し、未設定の場合はデフォルト 50 を使用する。
	FindRecentlyActive(ctx context.Context, requesterID string, since time.Time) ([]NearbyUserInfo, error)
}
