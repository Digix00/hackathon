package vo

import domainerrs "hackathon/internal/domain/errs"

// NotificationFrequency は通知頻度を表す値オブジェクト。
type NotificationFrequency string

const (
	NotificationFrequencyImmediate NotificationFrequency = "immediate"
	NotificationFrequencyHourly    NotificationFrequency = "hourly"
	NotificationFrequencyDaily     NotificationFrequency = "daily"
)

// ParseNotificationFrequency は文字列をNotificationFrequencyにパースする。
// 不正な値の場合はドメインエラーを返す。
func ParseNotificationFrequency(s string) (NotificationFrequency, error) {
	switch NotificationFrequency(s) {
	case NotificationFrequencyImmediate, NotificationFrequencyHourly, NotificationFrequencyDaily:
		return NotificationFrequency(s), nil
	}
	return "", domainerrs.BadRequest("notification_frequency is invalid")
}
