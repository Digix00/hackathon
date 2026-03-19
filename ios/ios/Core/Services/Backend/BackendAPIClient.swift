import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

actor BackendAPIClient {
    private static let apiPrefixSegments = ["api", "v1"]

    enum BackendError: Error {
        case invalidBaseURL
        case invalidResponse
        case missingAuthToken
        case unexpectedStatus(Int, String?)
    }

    private let session: URLSession
    private let baseURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // Percent-encode a single path component, ensuring "/" is always escaped.
    private func escapePathComponent(_ component: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return component.addingPercentEncoding(withAllowedCharacters: allowed) ?? component
    }

    init(session: URLSession = .shared) {
        self.session = session
        self.baseURL = Self.resolveBaseURL()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeFlexibleDate)
        self.decoder = decoder
    }

    // MARK: - Users

    func createUser(_ request: CreateUserRequest) async throws -> BackendUser {
        let result = try await send(path: "users", method: "POST", body: try encoder.encode(request))
        guard result.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendUserResponse.self, from: result.data).user
    }

    func getMe() async throws -> BackendUser {
        let result = try await send(path: "users/me", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendUserResponse.self, from: result.data).user
    }

    func getUser(id: String) async throws -> BackendPublicUser {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "users/\(escapedId)", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendPublicUserResponse.self, from: result.data).user
    }

    func patchMe(_ request: UpdateUserRequest) async throws -> BackendUser {
        let result = try await send(path: "users/me", method: "PATCH", body: try encoder.encode(request))
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendUserResponse.self, from: result.data).user
    }

    func deleteMe() async throws {
        let result = try await send(path: "users/me", method: "DELETE")
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    // MARK: - Settings

    func getMySettings() async throws -> BackendUserSettings {
        let result = try await send(path: "users/me/settings", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendUserSettingsResponse.self, from: result.data).settings
    }

    func patchMySettings(_ request: UpdateUserSettingsRequest) async throws -> BackendUserSettings {
        let result = try await send(path: "users/me/settings", method: "PATCH", body: try encoder.encode(request))
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendUserSettingsResponse.self, from: result.data).settings
    }

    // MARK: - Music Connections

    func listMusicConnections() async throws -> [BackendMusicConnection] {
        let result = try await send(path: "users/me/music-connections", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        let response = try decoder.decode(BackendMusicConnectionsResponse.self, from: result.data)
        return response.musicConnections ?? []
    }

    func getMusicAuthorizeURL(provider: MusicConnectionProvider) async throws -> BackendMusicAuthorizeResponse {
        let escapedProvider = escapePathComponent(provider.rawValue)
        let result = try await send(path: "music-connections/\(escapedProvider)/authorize", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendMusicAuthorizeResponse.self, from: result.data)
    }

    func deleteMusicConnection(provider: MusicConnectionProvider) async throws {
        let escapedProvider = escapePathComponent(provider.rawValue)
        let result = try await send(path: "users/me/music-connections/\(escapedProvider)", method: "DELETE")
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    // MARK: - Push Tokens

    func createPushToken(_ request: CreatePushTokenRequest) async throws -> BackendDevice {
        let result = try await send(path: "users/me/push-tokens", method: "POST", body: try encoder.encode(request))
        guard result.response.statusCode == 200 || result.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendDeviceResponse.self, from: result.data).device
    }

    func patchPushToken(id: String, request: UpdatePushTokenRequest) async throws -> BackendDevice {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "users/me/push-tokens/\(escapedId)", method: "PATCH", body: try encoder.encode(request))
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendDeviceResponse.self, from: result.data).device
    }

    func deletePushToken(id: String) async throws {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "users/me/push-tokens/\(escapedId)", method: "DELETE")
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    // MARK: - Notifications

    func listNotifications(limit: Int? = nil, offset: Int? = nil) async throws -> BackendNotificationListResponse {
        var queryItems: [URLQueryItem] = []
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        if let offset { queryItems.append(URLQueryItem(name: "offset", value: "\(offset)")) }

        let result = try await send(path: "users/me/notifications", method: "GET", queryItems: queryItems)
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendNotificationListResponse.self, from: result.data)
    }

    func markNotificationAsRead(id: String) async throws {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "users/me/notifications/\(escapedId)/read", method: "PATCH")
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    func deleteNotification(id: String) async throws {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "users/me/notifications/\(escapedId)", method: "DELETE")
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    // MARK: - Tracks

    func searchTracks(query: String, limit: Int? = nil, cursor: String? = nil) async throws -> BackendTrackSearchResponse {
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "q", value: query)]
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: cursor)) }

        let result = try await send(path: "tracks/search", method: "GET", queryItems: queryItems)
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendTrackSearchResponse.self, from: result.data)
    }

    func getTrack(id: String) async throws -> BackendPublicTrack {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "tracks/\(escapedId)", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }

        let response = try decoder.decode(BackendTrackResponse.self, from: result.data)
        guard let track = response.track else {
            throw BackendError.invalidResponse
        }
        return track
    }

    // MARK: - Reports

    func createReport(_ request: CreateReportRequest) async throws -> BackendReport {
        let result = try await send(path: "reports", method: "POST", body: try encoder.encode(request))
        guard result.response.statusCode == 200 || result.response.statusCode == 201 || result.response.statusCode == 409 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        if result.response.statusCode == 409 {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendReportResponse.self, from: result.data).report
    }

    // MARK: - Blocks & Mutes

    func createBlock(blockedUserId: String) async throws -> BackendBlock {
        let request = CreateBlockRequest(blockedUserId: blockedUserId)
        let result = try await send(path: "users/me/blocks", method: "POST", body: try encoder.encode(request))
        guard result.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        let response = try decoder.decode(BackendBlockResponse.self, from: result.data)
        guard let block = response.block else {
            throw BackendError.invalidResponse
        }
        return block
    }

    func deleteBlock(blockedUserId: String) async throws {
        let escapedId = escapePathComponent(blockedUserId)
        let result = try await send(path: "users/me/blocks/\(escapedId)", method: "DELETE")
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    func createMute(targetUserId: String) async throws -> BackendMute {
        let request = CreateMuteRequest(targetUserId: targetUserId)
        let result = try await send(path: "users/me/mutes", method: "POST", body: try encoder.encode(request))
        guard result.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        let response = try decoder.decode(BackendMuteResponse.self, from: result.data)
        guard let mute = response.mute else {
            throw BackendError.invalidResponse
        }
        return mute
    }

    func deleteMute(targetUserId: String) async throws {
        let escapedId = escapePathComponent(targetUserId)
        let result = try await send(path: "users/me/mutes/\(escapedId)", method: "DELETE")
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    // MARK: - Encounters

    func createEncounter(targetBleToken: String, rssi: Int, occurredAt: Date) async throws -> BackendEncounterSummary? {
        let request = CreateEncounterRequest(
            targetBleToken: targetBleToken,
            type: .ble,
            rssi: rssi,
            occurredAt: occurredAt
        )
        let result = try await send(path: "encounters", method: "POST", body: try encoder.encode(request))

        if result.response.statusCode == 204 {
            return nil
        }
        guard result.response.statusCode == 200 || result.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }

        return try decoder.decode(BackendEncounterResponse.self, from: result.data).encounter
    }

    func listEncounters(limit: Int? = nil, cursor: String? = nil) async throws -> BackendEncounterListResponse {
        var queryItems: [URLQueryItem] = []
        if let limit { queryItems.append(URLQueryItem(name: "limit", value: "\(limit)")) }
        if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: cursor)) }

        let result = try await send(path: "encounters", method: "GET", queryItems: queryItems)
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }

        return try decoder.decode(BackendEncounterListResponse.self, from: result.data)
    }

    func getEncounter(id: String) async throws -> BackendEncounterDetail {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "encounters/\(escapedId)", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }

        return try decoder.decode(BackendEncounterDetailResponse.self, from: result.data).encounter
    }

    @available(*, deprecated, message: "Use getEncounter(id:) instead.")
    func getEncounterByID(id: String) async throws -> BackendEncounterDetail {
        try await getEncounter(id: id)
    }

    // MARK: - Comments

    func listComments(encounterId: String) async throws -> BackendCommentListResponse {
        let escapedId = escapePathComponent(encounterId)
        let result = try await send(path: "encounters/\(escapedId)/comments", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }

        return try decoder.decode(BackendCommentListResponse.self, from: result.data)
    }

    func createComment(encounterId: String, content: String) async throws -> BackendComment {
        let escapedId = escapePathComponent(encounterId)
        let request = CreateCommentRequest(content: content)
        let result = try await send(
            path: "encounters/\(escapedId)/comments",
            method: "POST",
            body: try encoder.encode(request)
        )
        guard result.response.statusCode == 200 || result.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }

        let response = try decoder.decode(BackendCommentResponse.self, from: result.data)
        guard let comment = response.comment else {
            throw BackendError.invalidResponse
        }
        return comment
    }

    func deleteComment(id: String) async throws {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "comments/\(escapedId)", method: "DELETE")
        guard result.response.statusCode == 204 || result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    // MARK: - Playlists

    func getMyPlaylists() async throws -> BackendPlaylistListResponse {
        let result = try await send(path: "playlists/me", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendPlaylistListResponse.self, from: result.data)
    }

    func getPlaylist(id: String) async throws -> BackendPlaylist {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "playlists/\(escapedId)", method: "GET")
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendPlaylistResponse.self, from: result.data).playlist
    }

    func createPlaylist(_ request: CreatePlaylistRequest) async throws -> BackendPlaylist {
        let result = try await send(path: "playlists", method: "POST", body: try encoder.encode(request))
        guard result.response.statusCode == 201 || result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendPlaylistResponse.self, from: result.data).playlist
    }

    func updatePlaylist(id: String, request: UpdatePlaylistRequest) async throws -> BackendPlaylist {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "playlists/\(escapedId)", method: "PATCH", body: try encoder.encode(request))
        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
        return try decoder.decode(BackendPlaylistResponse.self, from: result.data).playlist
    }

    func deletePlaylist(id: String) async throws {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "playlists/\(escapedId)", method: "DELETE")
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    func addPlaylistTrack(id: String, trackId: String) async throws {
        let escapedId = escapePathComponent(id)
        let request = AddPlaylistTrackRequest(trackId: trackId)
        let result = try await send(
            path: "playlists/\(escapedId)/tracks",
            method: "POST",
            body: try encoder.encode(request)
        )
        guard result.response.statusCode == 204 || result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    func removePlaylistTrack(id: String, trackId: String) async throws {
        let escapedId = escapePathComponent(id)
        let escapedTrackId = escapePathComponent(trackId)
        let result = try await send(
            path: "playlists/\(escapedId)/tracks/\(escapedTrackId)",
            method: "DELETE"
        )
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    func addPlaylistFavorite(id: String) async throws {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "playlists/\(escapedId)/favorites", method: "POST")
        guard result.response.statusCode == 204 || result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    func removePlaylistFavorite(id: String) async throws {
        let escapedId = escapePathComponent(id)
        let result = try await send(path: "playlists/\(escapedId)/favorites", method: "DELETE")
        guard result.response.statusCode == 204 else {
            throw BackendError.unexpectedStatus(result.response.statusCode, result.bodyString)
        }
    }

    // MARK: - Internal

    private func send(
        path: String,
        method: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = []
    ) async throws -> (data: Data, response: HTTPURLResponse, bodyString: String?) {
        guard
            let baseURL,
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        else {
            throw BackendError.invalidBaseURL
        }

        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        components.path = Self.buildAPIPath(basePath: components.path, endpointPath: normalizedPath)
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw BackendError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let bearerToken = try await fetchBearerToken()
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        let bodyString = String(data: data, encoding: .utf8)
        return (data, httpResponse, bodyString)
    }

    private func fetchBearerToken() async throws -> String {
        if let fixed = ProcessInfo.processInfo.environment["FIREBASE_ID_TOKEN"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !fixed.isEmpty
        {
            return fixed
        }

#if canImport(FirebaseAuth)
        guard let user = Auth.auth().currentUser else {
            throw BackendError.missingAuthToken
        }

        return try await withCheckedThrowingContinuation { continuation in
            user.getIDToken { token, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let token, !token.isEmpty else {
                    continuation.resume(throwing: BackendError.missingAuthToken)
                    return
                }

                continuation.resume(returning: token)
            }
        }
#else
        throw BackendError.missingAuthToken
#endif
    }

    private static func resolveBaseURL() -> URL? {
        let candidates = [
            ProcessInfo.processInfo.environment["API_BASE_URL"],
            Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
            "http://localhost:8000"
        ]

        for raw in candidates {
            guard let value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
                continue
            }
            if let url = URL(string: value.hasSuffix("/") ? value : value + "/") {
                return url
            }
        }

        return nil
    }

    private static func buildAPIPath(basePath: String, endpointPath: String) -> String {
        let baseSegments = pathSegments(from: basePath)
        let endpointSegments = pathSegments(from: endpointPath)

        let endpointHasPrefix = endpointSegments.starts(with: apiPrefixSegments)
        let baseHasPrefix = baseSegments.suffix(apiPrefixSegments.count).elementsEqual(apiPrefixSegments)
        let needsPrefix = !endpointHasPrefix && !baseHasPrefix

        var merged = baseSegments
        if needsPrefix {
            merged.append(contentsOf: apiPrefixSegments)
        }
        if baseHasPrefix && endpointHasPrefix {
            merged.append(contentsOf: endpointSegments.dropFirst(apiPrefixSegments.count))
        } else {
            merged.append(contentsOf: endpointSegments)
        }

        return "/" + merged.joined(separator: "/")
    }

    private static func pathSegments(from rawPath: String) -> [String] {
        rawPath
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private static func decodeFlexibleDate(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        if let date = iso8601WithFractionalSeconds.date(from: string) {
            return date
        }
        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }
        if let date = dateOnlyFormatter.date(from: string) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date format: \(string)"
        )
    }

    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
