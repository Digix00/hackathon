package usecase

import "time"

// firebaseProvider はusecaseレイヤー全体で使うFirebase認証プロバイダー名。
const firebaseProvider = "firebase"

// Encounter limits (temporary defaults until config-driven values are introduced).
const (
	dailyEncounterPairLimit = 1
	dailyEncounterUserLimit = 10
	encounterDedupeWindow   = 5 * time.Minute
	rssiFilterMin           = -85
)
