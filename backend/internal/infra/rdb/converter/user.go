package converter

import (
	"hackathon/internal/domain/entity"
	"hackathon/internal/domain/vo"
	"hackathon/internal/infra/rdb/model"
)

// ModelToEntityUser は model.User をドメインエンティティに変換する。
// DB値は既にバリデーション済みとして信頼し、強制キャストする。
func ModelToEntityUser(user model.User) entity.User {
	var avatarURL *string
	if user.AvatarFile != nil {
		u := user.AvatarFile.FilePath
		avatarURL = &u
	}

	var prefectureName *string
	if user.Prefecture != nil {
		p := user.Prefecture.Name
		prefectureName = &p
	}

	return entity.User{
		ID:             user.ID,
		AuthProvider:   user.AuthProvider,
		ProviderUserID: user.ProviderUserID,
		Name:           user.Name,
		Bio:            user.Bio,
		Birthdate:      user.Birthdate,
		AgeVisibility:  vo.AgeVisibility(user.AgeVisibility),
		PrefectureID:   user.PrefectureID,
		PrefectureName: prefectureName,
		Sex:            vo.Sex(user.Sex),
		AvatarFileID:   user.AvatarFileID,
		AvatarURL:      avatarURL,
		CreatedAt:      user.CreatedAt,
		UpdatedAt:      user.UpdatedAt,
	}
}
