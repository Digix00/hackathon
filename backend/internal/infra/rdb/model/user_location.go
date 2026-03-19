package model

import "time"

type UserLocation struct {
	ID        string    `gorm:"primaryKey"`
	UserID    string    `gorm:"not null;uniqueIndex"`
	Latitude  float64   `gorm:"not null"`
	Longitude float64   `gorm:"not null"`
	UpdatedAt time.Time `gorm:"not null;autoUpdateTime;index"`
}
