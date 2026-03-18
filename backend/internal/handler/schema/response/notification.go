package response

type NotificationItem struct {
	ID          string  `json:"id"`
	EncounterID string  `json:"encounter_id"`
	Status      string  `json:"status"`
	ReadAt      *string `json:"read_at"`
	CreatedAt   string  `json:"created_at"`
}

type NotificationListResponse struct {
	Notifications []NotificationItem `json:"notifications"`
	UnreadCount   int64              `json:"unread_count"`
	Total         int64              `json:"total"`
}
