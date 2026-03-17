package converter

import (
	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/vo"
	"hackathon/internal/infra/rdb/model"
)

// ModelToEntityMusicConnection は model.MusicConnection をドメインエンティティに変換する。
// DB 値は既にバリデーション済みとして信頼し、強制キャストする。
func ModelToEntityMusicConnection(m model.MusicConnection) entity.MusicConnection {
	return entity.MusicConnection{
		ID:               m.ID,
		UserID:           m.UserID,
		Provider:         vo.MusicProvider(m.Provider),
		ProviderUserID:   m.ProviderUserID,
		ProviderUsername: m.ProviderUsername,
		AccessToken:      m.AccessToken,
		RefreshToken:     m.RefreshToken,
		ExpiresAt:        m.ExpiresAt,
		UpdatedAt:        m.UpdatedAt,
	}
}
