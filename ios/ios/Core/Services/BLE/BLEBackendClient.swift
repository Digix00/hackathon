import Foundation

struct BLEAdvertisingToken {
    let token: String
    let expiresAt: Date
}

actor BLEBackendClient {
    enum BackendError: Error {
        case invalidBaseURL
        case invalidResponse
        case invalidTokenPayload
        case unexpectedStatus(Int)
    }

    private let session: URLSession
    private let baseURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.baseURL = Self.resolveBaseURL()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(Self.decodeISO8601Date)
        self.decoder = decoder
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
        let request = EncounterCreateRequest(
            targetBleToken: targetBLEToken,
            type: "ble",
            rssi: rssi,
            occurredAt: occurredAt
        )
        let body = try encoder.encode(request)
        let result = try await send(path: "encounters", method: "POST", body: body)

        guard result.response.statusCode == 200 || result.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(result.response.statusCode)
        }
    }

    private func issueToken() async throws -> BLEAdvertisingToken {
        let issued = try await send(path: "ble-tokens", method: "POST")

        guard issued.response.statusCode == 200 || issued.response.statusCode == 201 else {
            throw BackendError.unexpectedStatus(issued.response.statusCode)
        }

        return try parseToken(from: issued.data)
    }

    private func parseToken(from data: Data) throws -> BLEAdvertisingToken {
        let envelope = try decoder.decode(BLETokenEnvelope.self, from: data)
        let token = envelope.bleToken.token.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !token.isEmpty else {
            throw BackendError.invalidTokenPayload
        }

        return BLEAdvertisingToken(token: token, expiresAt: envelope.bleToken.expiresAt)
    }

    private func send(path: String, method: String, body: Data? = nil) async throws -> (data: Data, response: HTTPURLResponse) {
        guard
            let baseURL,
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        else {
            throw BackendError.invalidBaseURL
        }

        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        components.path = components.path.appendingPathComponent(normalizedPath)

        guard let url = components.url else {
            throw BackendError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

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

    private static func resolveBaseURL() -> URL? {
        let candidates = [
            ProcessInfo.processInfo.environment["API_BASE_URL"],
            Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
            "http://localhost:8080"
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
}

private struct BLETokenEnvelope: Decodable {
    let bleToken: BLETokenPayload

    enum CodingKeys: String, CodingKey {
        case bleToken = "ble_token"
    }
}

private struct BLETokenPayload: Decodable {
    let token: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case token
        case expiresAt = "expires_at"
    }
}

private struct EncounterCreateRequest: Encodable {
    let targetBleToken: String
    let type: String
    let rssi: Int
    let occurredAt: Date

    enum CodingKeys: String, CodingKey {
        case targetBleToken = "target_ble_token"
        case type
        case rssi
        case occurredAt = "occurred_at"
    }
}

private extension String {
    func appendingPathComponent(_ component: String) -> String {
        if isEmpty || hasSuffix("/") {
            return self + component
        }
        return self + "/" + component
    }
}
