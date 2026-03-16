package vo

import domainerrs "hackathon/internal/domain/errs"

type Platform string

const (
	PlatformIOS     Platform = "ios"
	PlatformAndroid Platform = "android"
)

func ParsePlatform(s string) (Platform, error) {
	switch Platform(s) {
	case PlatformIOS, PlatformAndroid:
		return Platform(s), nil
	}
	return "", domainerrs.BadRequest("platform is invalid")
}
