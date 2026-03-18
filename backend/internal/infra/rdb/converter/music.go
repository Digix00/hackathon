package converter

import (
	"hackathon/internal/domain/entity"
	"hackathon/internal/infra/rdb/model"
)

func ModelToEntityMusicConnection(connection model.MusicConnection) entity.MusicConnection {
	return entity.MusicConnection{
		ID:               connection.ID,
		UserID:           connection.UserID,
		Provider:         connection.Provider,
		ProviderUserID:   connection.ProviderUserID,
		ProviderUsername: connection.ProviderUsername,
		AccessToken:      connection.AccessToken,
		RefreshToken:     connection.RefreshToken,
		ExpiresAt:        connection.ExpiresAt,
		CreatedAt:        connection.CreatedAt,
		UpdatedAt:        connection.UpdatedAt,
	}
}
