import Foundation

// MARK: - User

nonisolated struct BackendUser: Decodable, Equatable {
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

nonisolated struct BackendPublicUser: Decodable, Equatable {
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

nonisolated struct BackendPublicTrack: Decodable, Equatable {
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

nonisolated struct BackendUserResponse: Decodable {
    let user: BackendUser
}

nonisolated struct BackendPublicUserResponse: Decodable {
    let user: BackendPublicUser
}

// MARK: - User Settings

nonisolated struct BackendUserSettings: Decodable, Equatable {
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

nonisolated struct BackendUserSettingsResponse: Decodable {
    let settings: BackendUserSettings
}

// MARK: - Push Tokens

nonisolated struct BackendDevice: Decodable, Equatable {
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

nonisolated struct BackendDeviceResponse: Decodable {
    let device: BackendDevice
}

// MARK: - Notifications

nonisolated struct BackendNotificationItem: Decodable, Equatable {
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

nonisolated struct BackendNotificationListResponse: Decodable {
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

nonisolated struct BackendReport: Decodable, Equatable {
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

nonisolated struct BackendReportResponse: Decodable {
    let report: BackendReport
}

// MARK: - Encounters

// Encounter user shares the public user shape; extra fields may be nil here.
typealias BackendEncounterUser = BackendPublicUser

typealias BackendEncounterTrack = BackendPublicTrack

nonisolated enum BackendEncounterType: Decodable, Equatable {
    case ble
    case location
    case unknown(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "ble":
            self = .ble
        case "location":
            self = .location
        default:
            self = .unknown(rawValue)
        }
    }
}

nonisolated enum BackendEncounterCreateType: String, Encodable, Equatable {
    case ble
}

nonisolated struct BackendEncounterSummary: Decodable, Equatable {
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

nonisolated struct BackendEncounterListItem: Decodable, Equatable {
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

nonisolated struct BackendEncounterDetail: Decodable, Equatable {
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

nonisolated struct BackendEncounterResponse: Decodable {
    let encounter: BackendEncounterSummary
}

nonisolated struct BackendEncounterDetailResponse: Decodable {
    let encounter: BackendEncounterDetail
}

nonisolated struct BackendEncounterPagination: Decodable, Equatable {
    let nextCursor: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

nonisolated struct BackendEncounterListResponse: Decodable {
    let encounters: [BackendEncounterListItem]
    let pagination: BackendEncounterPagination
}

// MARK: - Comments

struct BackendCommentUser: Decodable, Equatable {
    let id: String?
    let displayName: String?
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
    }
}

struct BackendComment: Decodable, Equatable {
    let id: String?
    let encounterId: String?
    let content: String?
    let createdAt: Date?
    let user: BackendCommentUser?

    enum CodingKeys: String, CodingKey {
        case id
        case encounterId = "encounter_id"
        case content
        case createdAt = "created_at"
        case user
    }
}

struct BackendCommentPagination: Decodable, Equatable {
    let nextCursor: String?
    let hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
        case hasMore = "has_more"
    }
}

struct BackendCommentResponse: Decodable {
    let comment: BackendComment?
}

struct BackendCommentListResponse: Decodable {
    let comments: [BackendComment]?
    let pagination: BackendCommentPagination?
}

// MARK: - Playlists

nonisolated struct BackendPlaylistSummary: Decodable, Equatable {
    let id: String
    let name: String
    let description: String?
    let isPublic: Bool
    let userId: String
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case isPublic = "is_public"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

nonisolated struct BackendPlaylistTrack: Decodable, Equatable {
    let id: String
    let trackId: String
    let title: String
    let artistName: String
    let artworkURL: String?
    let sortOrder: Int
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case trackId = "track_id"
        case title
        case artistName = "artist_name"
        case artworkURL = "artwork_url"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

nonisolated struct BackendPlaylist: Decodable, Equatable {
    let id: String
    let name: String
    let description: String?
    let isPublic: Bool
    let userId: String
    let tracks: [BackendPlaylistTrack]
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case isPublic = "is_public"
        case userId = "user_id"
        case tracks
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

nonisolated struct BackendPlaylistListResponse: Decodable {
    let playlists: [BackendPlaylistSummary]
}

nonisolated struct BackendPlaylistResponse: Decodable {
    let playlist: BackendPlaylist
}

// MARK: - Requests

nonisolated struct CreateUserRequest: Encodable {
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

nonisolated struct UpdateUserRequest: Encodable {
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

nonisolated struct UpdateUserSettingsRequest: Encodable {
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

    init(
        bleEnabled: Bool? = nil,
        locationEnabled: Bool? = nil,
        detectionDistance: Int? = nil,
        scheduleEnabled: Bool? = nil,
        scheduleStartTime: String? = nil,
        scheduleEndTime: String? = nil,
        profileVisible: Bool? = nil,
        trackVisible: Bool? = nil,
        notificationEnabled: Bool? = nil,
        encounterNotificationEnabled: Bool? = nil,
        batchNotificationEnabled: Bool? = nil,
        notificationFrequency: String? = nil,
        commentNotificationEnabled: Bool? = nil,
        likeNotificationEnabled: Bool? = nil,
        announcementNotificationEnabled: Bool? = nil,
        themeMode: String? = nil
    ) {
        self.bleEnabled = bleEnabled
        self.locationEnabled = locationEnabled
        self.detectionDistance = detectionDistance
        self.scheduleEnabled = scheduleEnabled
        self.scheduleStartTime = scheduleStartTime
        self.scheduleEndTime = scheduleEndTime
        self.profileVisible = profileVisible
        self.trackVisible = trackVisible
        self.notificationEnabled = notificationEnabled
        self.encounterNotificationEnabled = encounterNotificationEnabled
        self.batchNotificationEnabled = batchNotificationEnabled
        self.notificationFrequency = notificationFrequency
        self.commentNotificationEnabled = commentNotificationEnabled
        self.likeNotificationEnabled = likeNotificationEnabled
        self.announcementNotificationEnabled = announcementNotificationEnabled
        self.themeMode = themeMode
    }

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

nonisolated struct CreatePushTokenRequest: Encodable {
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

nonisolated struct UpdatePushTokenRequest: Encodable {
    let pushToken: String?
    let enabled: Bool?
    let appVersion: String?

    enum CodingKeys: String, CodingKey {
        case pushToken = "push_token"
        case enabled
        case appVersion = "app_version"
    }
}

nonisolated struct CreateReportRequest: Encodable {
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

nonisolated struct CreateEncounterRequest: Encodable {
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

struct CreateCommentRequest: Encodable {
    let content: String
}

nonisolated struct CreatePlaylistRequest: Encodable {
    let name: String
    let description: String?
    let isPublic: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case isPublic = "is_public"
    }
}

nonisolated struct UpdatePlaylistRequest: Encodable {
    let name: String?
    let description: String?
    let isPublic: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case isPublic = "is_public"
    }
}

nonisolated struct AddPlaylistTrackRequest: Encodable {
    let trackId: String

    enum CodingKeys: String, CodingKey {
        case trackId = "track_id"
    }
}
