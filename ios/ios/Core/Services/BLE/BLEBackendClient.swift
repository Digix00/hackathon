import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
import Security

struct BLEAdvertisingToken {
    let token: String
    let expiresAt: Date
}

struct BLEPublicUser: Equatable {
    let id: String
    let displayName: String
    let avatarURL: String?
}

actor BLEBackendClient {
    private static let apiPrefixSegments = ["api", "v1"]
    private static let pendingEncounterStorageKey = "ble.pending.encounters.v1"
    private static let failedEncounterStorageKey = "ble.failed.encounters.v1"
    private static let initialRetryDelaySeconds: UInt64 = 5
    private static let maxRetryDelaySeconds: UInt64 = 300
    private static let maxRetryAttempts = 6

    enum BackendError: Error {
        case invalidBaseURL
        case invalidResponse
        case invalidTokenPayload
        case missingAuthToken
        case unexpectedStatus(Int)
    }

    private let session: URLSession
    private let baseURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var pendingEncounters: [PendingEncounter]
    private var failedEncounters: [FailedEncounter]
    private var isDrainingQueue = false

    init(session: URLSession = .shared) {
        self.session = session
        self.baseURL = Self.resolveBaseURL()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeISO8601Date)
        self.decoder = decoder

        self.pendingEncounters = Self.loadPendingEncounters()
        self.failedEncounters = Self.loadFailedEncounters()
        Task {
            await self.startQueueDrainIfNeeded()
        }
    }

    func fetchOrIssueCurrentToken() async throws -> BLEAdvertisingToken {
        let current = try await send(path: "ble-tokens/current", method: "GET")

        if current.response.statusCode == 200 {
            return try parseToken(from: current.data)
        }

        if current.response.statusCode == 404 {
            return try await issueToken()
        }

        throw BackendError.unexpectedStatus(current.response.statusCode)
    }

    func postEncounter(targetBLEToken: String, rssi: Int, occurredAt: Date) async throws {
        let body = try Self.encodeEncounterCreateRequest(
            targetBleToken: targetBLEToken,
            rssi: rssi,
            occurredAt: occurredAt
        )
        let result = try await send(path: "encounters", method: "POST", body: body)

        guard result.response.statusCode == 200 || result.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(result.response.statusCode)
        }
    }

    func fetchUser(forBLEToken token: String) async throws -> BLEPublicUser {
        let encodedToken = token.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? token
        let result = try await send(path: "ble-tokens/\(encodedToken)/user", method: "GET")

        guard result.response.statusCode == 200 else {
            throw BackendError.unexpectedStatus(result.response.statusCode)
        }

        return try Self.parseUser(from: result.data)
    }

    func enqueueEncounter(targetBLEToken: String, rssi: Int, occurredAt: Date) {
        pendingEncounters.append(
            PendingEncounter(
                targetBLEToken: targetBLEToken,
                rssi: rssi,
                occurredAtEpochMs: Int64(occurredAt.timeIntervalSince1970 * 1_000),
                attempts: 0
            )
        )
        persistPendingEncounters()
        startQueueDrainIfNeeded()
    }

    private func issueToken() async throws -> BLEAdvertisingToken {
        let issued = try await send(path: "ble-tokens", method: "POST")

        guard issued.response.statusCode == 200 || issued.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(issued.response.statusCode)
        }

        return try parseToken(from: issued.data)
    }

    private func parseToken(from data: Data) throws -> BLEAdvertisingToken {
        let payload = try Self.decodeJSONObject(from: data)
        guard
            let bleToken = payload["ble_token"] as? [String: Any],
            let rawToken = bleToken["token"] as? String,
            let expiresAtRaw = bleToken["expires_at"] as? String,
            let expiresAt = Self.decodeISO8601Date(from: expiresAtRaw)
        else {
            throw BackendError.invalidTokenPayload
        }

        let token = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !token.isEmpty else {
            throw BackendError.invalidTokenPayload
        }

        return BLEAdvertisingToken(token: token, expiresAt: expiresAt)
    }

    private func send(path: String, method: String, body: Data? = nil) async throws -> (data: Data, response: HTTPURLResponse) {
        guard
            let baseURL,
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        else {
            throw BackendError.invalidBaseURL
        }

        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        components.path = Self.buildAPIPath(basePath: components.path, endpointPath: normalizedPath)

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

        return (data, httpResponse)
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
            if let url = URL(string: value.hasSuffix("/") ? value : value + "/"),
               !isPlaceholderBaseURL(url) {
                return url
            }
        }

        return nil
    }

    private static func isPlaceholderBaseURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "example.com" || host.hasSuffix(".example.com")
    }

    private static func decodeISO8601Date(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        if let date = iso8601WithFractionalSeconds.date(from: string) ?? ISO8601DateFormatter().date(from: string) {
            return date
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid ISO8601 date: \(string)"
        )
    }

    private static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

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

    private static func encodeEncounterCreateRequest(
        targetBleToken: String,
        rssi: Int,
        occurredAt: Date
    ) throws -> Data {
        let formatter = ISO8601DateFormatter()
        let payload: [String: Any] = [
            "target_ble_token": targetBleToken,
            "type": "ble",
            "rssi": rssi,
            "occurred_at": formatter.string(from: occurredAt)
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    private static func parseUser(from data: Data) throws -> BLEPublicUser {
        let payload = try decodeJSONObject(from: data)
        guard
            let user = payload["user"] as? [String: Any],
            let id = user["id"] as? String,
            let displayName = user["display_name"] as? String
        else {
            throw BackendError.invalidResponse
        }

        return BLEPublicUser(
            id: id,
            displayName: displayName,
            avatarURL: user["avatar_url"] as? String
        )
    }

    private static func decodeJSONObject(from data: Data) throws -> [String: Any] {
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BackendError.invalidResponse
        }
        return object
    }

    private static func decodeISO8601Date(from raw: String) -> Date? {
        let formatterWithFractionalSeconds = ISO8601DateFormatter()
        formatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFractionalSeconds.date(from: raw) {
            return date
        }
        return ISO8601DateFormatter().date(from: raw)
    }

    private func startQueueDrainIfNeeded() {
        guard !isDrainingQueue, !pendingEncounters.isEmpty else { return }

        isDrainingQueue = true
        Task {
            await self.drainPendingEncounterQueue()
        }
    }

    private func drainPendingEncounterQueue() async {
        defer { isDrainingQueue = false }

        var retryDelaySeconds = Self.initialRetryDelaySeconds
        while !pendingEncounters.isEmpty {
            var next = pendingEncounters[0]
            let occurredAt = Date(timeIntervalSince1970: TimeInterval(next.occurredAtEpochMs) / 1_000)

            do {
                try await postEncounter(
                    targetBLEToken: next.targetBLEToken,
                    rssi: next.rssi,
                    occurredAt: occurredAt
                )
                pendingEncounters.removeFirst()
                persistPendingEncounters()
                retryDelaySeconds = Self.initialRetryDelaySeconds
            } catch {
                if case let BackendError.unexpectedStatus(statusCode) = error,
                   Self.isPermanentHTTPFailure(statusCode)
                {
                    markAsFailedAndDropPending(
                        encounter: next,
                        statusCode: statusCode,
                        reason: "permanent_http_failure"
                    )
                    retryDelaySeconds = Self.initialRetryDelaySeconds
                    continue
                }

                next.attempts += 1
                if next.attempts >= Self.maxRetryAttempts {
                    markAsFailedAndDropPending(
                        encounter: next,
                        statusCode: nil,
                        reason: "max_retry_exceeded"
                    )
                    retryDelaySeconds = Self.initialRetryDelaySeconds
                    continue
                }

                pendingEncounters[0] = next
                persistPendingEncounters()
                try? await Task.sleep(nanoseconds: retryDelaySeconds * 1_000_000_000)
                retryDelaySeconds = min(retryDelaySeconds * 2, Self.maxRetryDelaySeconds)
            }
        }
    }

    private func markAsFailedAndDropPending(encounter: PendingEncounter, statusCode: Int?, reason: String) {
        if !pendingEncounters.isEmpty {
            pendingEncounters.removeFirst()
        }
        persistPendingEncounters()

        failedEncounters.append(
            FailedEncounter(
                targetBLEToken: encounter.targetBLEToken,
                rssi: encounter.rssi,
                occurredAtEpochMs: encounter.occurredAtEpochMs,
                attempts: encounter.attempts,
                failedAtEpochMs: Int64(Date().timeIntervalSince1970 * 1_000),
                statusCode: statusCode,
                reason: reason
            )
        )
        persistFailedEncounters()
    }

    private func persistPendingEncounters() {
        let payload = pendingEncounters.map { $0.dictionaryValue }
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        KeychainStore.write(data: data, key: Self.pendingEncounterStorageKey)
    }

    private static func loadPendingEncounters() -> [PendingEncounter] {
        guard
            let data = KeychainStore.readData(key: pendingEncounterStorageKey),
            let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return []
        }
        return rawArray.compactMap { PendingEncounter(dictionary: $0) }
    }

    private func persistFailedEncounters() {
        let payload = failedEncounters.map { $0.dictionaryValue }
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        KeychainStore.write(data: data, key: Self.failedEncounterStorageKey)
    }

    private static func loadFailedEncounters() -> [FailedEncounter] {
        guard
            let data = KeychainStore.readData(key: failedEncounterStorageKey),
            let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return []
        }
        return rawArray.compactMap { FailedEncounter(dictionary: $0) }
    }

    private static func isPermanentHTTPFailure(_ statusCode: Int) -> Bool {
        if statusCode == 408 || statusCode == 429 {
            return false
        }
        if (400...499).contains(statusCode) {
            return true
        }
        return false
    }
}

private struct PendingEncounter {
    let targetBLEToken: String
    let rssi: Int
    let occurredAtEpochMs: Int64
    var attempts: Int

    nonisolated init(targetBLEToken: String, rssi: Int, occurredAtEpochMs: Int64, attempts: Int) {
        self.targetBLEToken = targetBLEToken
        self.rssi = rssi
        self.occurredAtEpochMs = occurredAtEpochMs
        self.attempts = attempts
    }

    nonisolated var dictionaryValue: [String: Any] {
        [
            "targetBLEToken": targetBLEToken,
            "rssi": rssi,
            "occurredAtEpochMs": occurredAtEpochMs,
            "attempts": attempts
        ]
    }

    nonisolated init?(dictionary: [String: Any]) {
        guard
            let targetBLEToken = Self.stringValue(in: dictionary, primaryKey: "targetBLEToken", legacyKey: "target_ble_token"),
            let rssi = Self.intValue(from: dictionary["rssi"]),
            let occurredAtEpochMs = Self.int64Value(in: dictionary, primaryKey: "occurredAtEpochMs", legacyKey: "occurred_at_epoch_ms"),
            let attempts = Self.intValue(from: dictionary["attempts"])
        else {
            return nil
        }

        self.targetBLEToken = targetBLEToken
        self.rssi = rssi
        self.occurredAtEpochMs = occurredAtEpochMs
        self.attempts = attempts
    }

    nonisolated static func intValue(from raw: Any?) -> Int? {
        if let value = raw as? Int {
            return value
        }
        if let number = raw as? NSNumber {
            return number.intValue
        }
        return nil
    }

    nonisolated static func stringValue(in dictionary: [String: Any], primaryKey: String, legacyKey: String) -> String? {
        if let value = dictionary[primaryKey] as? String {
            return value
        }
        return dictionary[legacyKey] as? String
    }

    nonisolated static func int64Value(from raw: Any?) -> Int64? {
        if let value = raw as? Int64 {
            return value
        }
        if let value = raw as? Int {
            return Int64(value)
        }
        if let number = raw as? NSNumber {
            return number.int64Value
        }
        return nil
    }

    nonisolated static func int64Value(in dictionary: [String: Any], primaryKey: String, legacyKey: String) -> Int64? {
        if let value = int64Value(from: dictionary[primaryKey]) {
            return value
        }
        return int64Value(from: dictionary[legacyKey])
    }
}

private struct FailedEncounter {
    let targetBLEToken: String
    let rssi: Int
    let occurredAtEpochMs: Int64
    let attempts: Int
    let failedAtEpochMs: Int64
    let statusCode: Int?
    let reason: String

    nonisolated init(
        targetBLEToken: String,
        rssi: Int,
        occurredAtEpochMs: Int64,
        attempts: Int,
        failedAtEpochMs: Int64,
        statusCode: Int?,
        reason: String
    ) {
        self.targetBLEToken = targetBLEToken
        self.rssi = rssi
        self.occurredAtEpochMs = occurredAtEpochMs
        self.attempts = attempts
        self.failedAtEpochMs = failedAtEpochMs
        self.statusCode = statusCode
        self.reason = reason
    }

    nonisolated var dictionaryValue: [String: Any] {
        [
            "targetBLEToken": targetBLEToken,
            "rssi": rssi,
            "occurredAtEpochMs": occurredAtEpochMs,
            "attempts": attempts,
            "failedAtEpochMs": failedAtEpochMs,
            "statusCode": statusCode as Any,
            "reason": reason
        ]
    }

    nonisolated init?(dictionary: [String: Any]) {
        guard
            let targetBLEToken = PendingEncounter.stringValue(in: dictionary, primaryKey: "targetBLEToken", legacyKey: "target_ble_token"),
            let rssi = PendingEncounter.intValue(from: dictionary["rssi"]),
            let occurredAtEpochMs = PendingEncounter.int64Value(in: dictionary, primaryKey: "occurredAtEpochMs", legacyKey: "occurred_at_epoch_ms"),
            let attempts = PendingEncounter.intValue(from: dictionary["attempts"]),
            let failedAtEpochMs = PendingEncounter.int64Value(in: dictionary, primaryKey: "failedAtEpochMs", legacyKey: "failed_at_epoch_ms"),
            let reason = dictionary["reason"] as? String
        else {
            return nil
        }

        self.targetBLEToken = targetBLEToken
        self.rssi = rssi
        self.occurredAtEpochMs = occurredAtEpochMs
        self.attempts = attempts
        self.failedAtEpochMs = failedAtEpochMs
        self.statusCode =
            PendingEncounter.intValue(from: dictionary["statusCode"]) ??
            PendingEncounter.intValue(from: dictionary["status_code"])
        self.reason = reason
    }
}

private enum KeychainStore {
    nonisolated private static let service = Bundle.main.bundleIdentifier ?? "com.digix00.musicswapping.ble"

    nonisolated static func write(data: Data, key: String) {
        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        var addQuery = baseQuery
        addQuery[kSecValueData] = data
        addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    nonisolated static func readData(key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }
}
