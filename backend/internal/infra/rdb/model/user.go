package model

import (
	"time"

	"gorm.io/gorm"
)

type Prefecture struct {
	ID   string `gorm:"primaryKey"`
	Name string `gorm:"not null"`
}

type File struct {
	ID               string         `gorm:"primaryKey"`
	FilePath         string         `gorm:"not null"`
	FileType         string         `gorm:"not null"`
	MimeType         string         `gorm:"not null"`
	FileSize         int            `gorm:"not null"`
	UploadedByUserID string         `gorm:"not null"`
	CreatedAt        time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt        gorm.DeletedAt `gorm:"index"` // #1 MUST: soft delete フィルタのため gorm.DeletedAt を使用
}

type User struct {
	ID             string         `gorm:"primaryKey"`
	AuthProvider   string         `gorm:"not null;uniqueIndex:uq_users_provider"`
	ProviderUserID string         `gorm:"not null;uniqueIndex:uq_users_provider"`
	Name           *string
	NameKana       *string
	NameUpdatedAt  *time.Time
	Bio            *string
	Birthdate      *time.Time
	AgeVisibility  string         `gorm:"not null;default:hidden"`
	PrefectureID   *string        `gorm:"index"`
	Sex            string         `gorm:"not null;default:no-answer"`
	IsRestricted   bool           `gorm:"not null;default:false"`
	AvatarFileID   *string
	AvatarShape    string         `gorm:"not null;default:circle"`
	CreatedAt      time.Time      `gorm:"not null;autoCreateTime"`
	UpdatedAt      time.Time      `gorm:"not null;autoUpdateTime"`
	DeletedAt      gorm.DeletedAt `gorm:"index"` // #1 MUST

	// Associations
	Prefecture *Prefecture `gorm:"foreignKey:PrefectureID"`
	AvatarFile *File       `gorm:"foreignKey:AvatarFileID"`
}

type UserSettings struct {
	ID                              string    `gorm:"primaryKey"`
	UserID                          string    `gorm:"not null;uniqueIndex"`
	BleEnabled                      bool      `gorm:"not null;default:true"`
	LocationEnabled                 bool      `gorm:"not null;default:true"`
	DetectionDistance               int       `gorm:"not null;default:50"`
	ScheduleEnabled                 bool      `gorm:"not null;default:false"`
	ScheduleStartTime               *string   // TIME 型は string で保持
	ScheduleEndTime                 *string
	ProfileVisible                  bool      `gorm:"not null;default:true"`
	TrackVisible                    bool      `gorm:"not null;default:true"`
	NotificationEnabled             bool      `gorm:"not null;default:true"`
	EncounterNotificationEnabled    bool      `gorm:"not null;default:true"`
	BatchNotificationEnabled        bool      `gorm:"not null;default:true"`
	NotificationFrequency           string    `gorm:"not null;default:hourly"`
	CommentNotificationEnabled      bool      `gorm:"not null;default:true"`
	LikeNotificationEnabled         bool      `gorm:"not null;default:true"`
	AnnouncementNotificationEnabled bool      `gorm:"not null;default:true"`
	ThemeMode                       string    `gorm:"not null;default:system"`
	CreatedAt                       time.Time `gorm:"not null;autoCreateTime"`
	UpdatedAt                       time.Time `gorm:"not null;autoUpdateTime"`
}

type UserDevice struct {
	ID          string    `gorm:"primaryKey"`
	UserID      string    `gorm:"not null;index"`
	DeviceToken string    `gorm:"not null;uniqueIndex"`
	Platform    string    `gorm:"not null"` // 'ios' | 'android'
	CreatedAt   time.Time `gorm:"not null;autoCreateTime"`
	UpdatedAt   time.Time `gorm:"not null;autoUpdateTime"`
}

// MusicConnection は Spotify / Apple Music の OAuth 連携情報を保持する。
// AccessToken / RefreshToken は DB 漏洩時のトークン流出を防ぐため、
// TODO: 本番運用前にアプリ層で AES-GCM 暗号化して保存すること。
// 参考: gorm Scanner/Valuer インターフェースを実装したカスタム型で透過的に暗号化できる。
type MusicConnection struct {
	ID               string     `gorm:"primaryKey"`
	UserID           string     `gorm:"not null;uniqueIndex:uq_music_connections"`
	Provider         string     `gorm:"not null;uniqueIndex:uq_music_connections"` // 'spotify' | 'apple_music'
	ProviderUserID   string     `gorm:"not null"`
	ProviderUsername *string
	AccessToken      string     `gorm:"not null"`  // #4 MUST: 要暗号化（TODO 参照）
	RefreshToken     *string                        // #4 MUST: 要暗号化（TODO 参照）
	ExpiresAt        *time.Time
	CreatedAt        time.Time  `gorm:"not null;autoCreateTime"`
	UpdatedAt        time.Time  `gorm:"not null;autoUpdateTime"`
}

type BleToken struct {
	ID        string         `gorm:"primaryKey"`
	UserID    string         `gorm:"not null;index"`
	Token     string         `gorm:"not null;uniqueIndex"`
	ValidFrom time.Time      `gorm:"not null"`
	ValidTo   time.Time      `gorm:"not null;index"`
	CreatedAt time.Time      `gorm:"not null;autoCreateTime"`
	DeletedAt gorm.DeletedAt `gorm:"index"` // #1 MUST
}
