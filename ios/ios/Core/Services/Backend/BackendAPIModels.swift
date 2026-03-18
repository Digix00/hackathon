import Foundation

// MARK: - User

struct BackendUser: Decodable, Equatable {
    let id: String
    let displayName: String
    let avatarURL: String?
    let bio: String?
    let birthdate: String?
    let ageVisibility: String?
    let prefectureId: String?
    let sex: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case bio
        case birthdate
        case ageVisibility = "age_visibility"
        case prefectureId = "prefecture_id"
        case sex
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct BackendPublicUser: Decodable, Equatable {
    let id: String
    let displayName: String
    let avatarURL: String?
    let bio: String?
    let birthplace: String?
    let ageRange: String?
    let encounterCount: Int?
    let sharedTrack: BackendPublicTrack?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case bio
        case birthplace
        case ageRange = "age_range"
        case encounterCount = "encounter_count"
        case sharedTrack = "shared_track"
        case updatedAt = "updated_at"
    }
}

struct BackendPublicTrack: Decodable, Equatable {
    let id: String
    let title: String
    let artistName: String
    let artworkURL: String?
    let previewURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artistName = "artist_name"
        case artworkURL = "artwork_url"
        case previewURL = "preview_url"
    }
}

struct BackendUserResponse: Decodable {
    let user: BackendUser
}

struct BackendPublicUserResponse: Decodable {
    let user: BackendPublicUser
}

// MARK: - User Settings

struct BackendUserSettings: Decodable, Equatable {
    let bleEnabled: Bool
    let locationEnabled: Bool
    let detectionDistance: Int
    let scheduleEnabled: Bool
    let scheduleStartTime: String?
    let scheduleEndTime: String?
    let profileVisible: Bool
    let trackVisible: Bool
    let notificationEnabled: Bool
    let encounterNotificationEnabled: Bool
    let batchNotificationEnabled: Bool
    let notificationFrequency: String
    let commentNotificationEnabled: Bool
    let likeNotificationEnabled: Bool
    let announcementNotificationEnabled: Bool
    let themeMode: String
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case bleEnabled = "ble_enabled"
        case locationEnabled = "location_enabled"
        case detectionDistance = "detection_distance"
        case scheduleEnabled = "schedule_enabled"
        case scheduleStartTime = "schedule_start_time"
        case scheduleEndTime = "schedule_end_time"
        case profileVisible = "profile_visible"
        case trackVisible = "track_visible"
        case notificationEnabled = "notification_enabled"
        case encounterNotificationEnabled = "encounter_notification_enabled"
        case batchNotificationEnabled = "batch_notification_enabled"
        case notificationFrequency = "notification_frequency"
        case commentNotificationEnabled = "comment_notification_enabled"
        case likeNotificationEnabled = "like_notification_enabled"
        case announcementNotificationEnabled = "announcement_notification_enabled"
        case themeMode = "theme_mode"
        case updatedAt = "updated_at"
    }
}

struct BackendUserSettingsResponse: Decodable {
    let settings: BackendUserSettings
}

// MARK: - Push Tokens

struct BackendDevice: Decodable, Equatable {
    let id: String
    let platform: String
    let deviceId: String
    let enabled: Bool
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case platform
        case deviceId = "device_id"
        case enabled
        case updatedAt = "updated_at"
    }
}

struct BackendDeviceResponse: Decodable {
    let device: BackendDevice
}

// MARK: - Notifications

struct BackendNotificationItem: Decodable, Equatable {
    let id: String
    let encounterId: String
    let status: String
    let readAt: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case encounterId = "encounter_id"
        case status
        case readAt = "read_at"
        case createdAt = "created_at"
    }
}

struct BackendNotificationListResponse: Decodable {
    let notifications: [BackendNotificationItem]
    let unreadCount: Int64
    let total: Int64

    enum CodingKeys: String, CodingKey {
        case notifications
        case unreadCount = "unread_count"
        case total
    }
}

// MARK: - Reports

struct BackendReport: Decodable, Equatable {
    let id: String
    let reportType: String
    let reportedUserId: String
    let targetCommentId: String?
    let reason: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case reportType = "report_type"
        case reportedUserId = "reported_user_id"
        case targetCommentId = "target_comment_id"
        case reason
        case createdAt = "created_at"
    }
}

struct BackendReportResponse: Decodable {
    let report: BackendReport
}

// MARK: - Encounters

// Encounter user shares the public user shape; extra fields may be nil here.
typealias BackendEncounterUser = BackendPublicUser

typealias BackendEncounterTrack = BackendPublicTrack

enum BackendEncounterType: String, Decodable, Equatable {
    case ble
    case location
}

enum BackendEncounterCreateType: String, Encodable, Equatable {
    case ble
}

struct BackendEncounterSummary: Decodable, Equatable {
    let id: String
    let type: BackendEncounterType
    let user: BackendEncounterUser
    let occurredAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case user
        case occurredAt = "occurred_at"
    }
}

struct BackendEncounterListItem: Decodable, Equatable {
    let id: String
    let type: BackendEncounterType
    let user: BackendEncounterUser
    let isRead: Bool
    let tracks: [BackendEncounterTrack]
    let occurredAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case user
        case isRead = "is_read"
        case tracks
        case occurredAt = "occurred_at"
    }
}

struct BackendEncounterDetail: Decodable, Equatable {
    let id: String
    let type: BackendEncounterType
    let user: BackendEncounterUser
    let occurredAt: Date?
    let tracks: [BackendEncounterTrack]

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case user
        case occurredAt = "occurred_at"
        case tracks
    }
}

struct BackendEncounterResponse: Decodable {
    let encounter: BackendEncounterSummary
}

struct BackendEncounterDetailResponse: Decodable {
    let encounter: BackendEncounterDetail
}

struct BackendEncounterPagination: Decodable, Equatable {
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

struct BackendEncounterListResponse: Decodable {
    let encounters: [BackendEncounterListItem]
    let pagination: BackendEncounterPagination
}

// MARK: - Requests

struct CreateUserRequest: Encodable {
    let displayName: String
    let avatarURL: String?
    let bio: String?
    let birthdate: String?
    let ageVisibility: String?
    let prefectureId: String?
    let sex: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case bio
        case birthdate
        case ageVisibility = "age_visibility"
        case prefectureId = "prefecture_id"
        case sex
    }
}

struct UpdateUserRequest: Encodable {
    let displayName: String?
    let avatarURL: String?
    let bio: String?
    let birthdate: String?
    let ageVisibility: String?
    let prefectureId: String?
    let sex: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case bio
        case birthdate
        case ageVisibility = "age_visibility"
        case prefectureId = "prefecture_id"
        case sex
    }
}

struct UpdateUserSettingsRequest: Encodable {
    let bleEnabled: Bool?
    let locationEnabled: Bool?
    let detectionDistance: Int?
    let scheduleEnabled: Bool?
    let scheduleStartTime: String?
    let scheduleEndTime: String?
    let profileVisible: Bool?
    let trackVisible: Bool?
    let notificationEnabled: Bool?
    let encounterNotificationEnabled: Bool?
    let batchNotificationEnabled: Bool?
    let notificationFrequency: String?
    let commentNotificationEnabled: Bool?
    let likeNotificationEnabled: Bool?
    let announcementNotificationEnabled: Bool?
    let themeMode: String?

    enum CodingKeys: String, CodingKey {
        case bleEnabled = "ble_enabled"
        case locationEnabled = "location_enabled"
        case detectionDistance = "detection_distance"
        case scheduleEnabled = "schedule_enabled"
        case scheduleStartTime = "schedule_start_time"
        case scheduleEndTime = "schedule_end_time"
        case profileVisible = "profile_visible"
        case trackVisible = "track_visible"
        case notificationEnabled = "notification_enabled"
        case encounterNotificationEnabled = "encounter_notification_enabled"
        case batchNotificationEnabled = "batch_notification_enabled"
        case notificationFrequency = "notification_frequency"
        case commentNotificationEnabled = "comment_notification_enabled"
        case likeNotificationEnabled = "like_notification_enabled"
        case announcementNotificationEnabled = "announcement_notification_enabled"
        case themeMode = "theme_mode"
    }
}

struct CreatePushTokenRequest: Encodable {
    let platform: String
    let deviceId: String
    let pushToken: String
    let appVersion: String?

    enum CodingKeys: String, CodingKey {
        case platform
        case deviceId = "device_id"
        case pushToken = "push_token"
        case appVersion = "app_version"
    }
}

struct UpdatePushTokenRequest: Encodable {
    let pushToken: String?
    let enabled: Bool?
    let appVersion: String?

    enum CodingKeys: String, CodingKey {
        case pushToken = "push_token"
        case enabled
        case appVersion = "app_version"
    }
}

struct CreateReportRequest: Encodable {
    let reportType: String
    let reportedUserId: String
    let targetCommentId: String?
    let reason: String

    enum CodingKeys: String, CodingKey {
        case reportType = "report_type"
        case reportedUserId = "reported_user_id"
        case targetCommentId = "target_comment_id"
        case reason
    }
}

struct CreateEncounterRequest: Encodable {
    let targetBleToken: String
    let type: BackendEncounterCreateType
    let rssi: Int
    let occurredAt: Date

    enum CodingKeys: String, CodingKey {
        case targetBleToken = "target_ble_token"
        case type
        case rssi
        case occurredAt = "occurred_at"
    }
}
