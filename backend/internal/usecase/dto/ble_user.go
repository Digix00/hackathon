package dto

// BleUserDTO is the minimal user info returned by the BLE token lookup endpoint.
// Only id, display_name, and avatar_url are exposed since BLE tokens can be
// scanned by any nearby device.
type BleUserDTO struct {
	ID          string
	DisplayName string
	AvatarURL   *string
}
