import Foundation
import Security
import Testing
@testable import ios

@Suite(.serialized)
struct BLEBackendClientTests {
    @Test("POST /encounters は /api/v1 プレフィックスと Authorization を付与する")
    func postEncounterAddsPrefixAndAuthorization() async throws {
        clearKeychainState()
        defer { clearKeychainState() }

        setenv("API_BASE_URL", "https://example.com", 1)
        setenv("FIREBASE_ID_TOKEN", "token-for-test", 1)
        defer {
            unsetenv("API_BASE_URL")
            unsetenv("FIREBASE_ID_TOKEN")
        }

        URLProtocolStub.reset()
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/api/v1/encounters")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-for-test")
            return HTTPStubResponse(statusCode: 201, body: Data("{}".utf8))
        }

        let client = BLEBackendClient(session: makeStubSession())
        try await client.postEncounter(
            targetBLEToken: "peer-token",
            rssi: -55,
            occurredAt: Date(timeIntervalSince1970: 1_710_000_000)
        )

        #expect(URLProtocolStub.recordedRequests.count == 1)
    }

    @Test("API_BASE_URL が /api/v1 を含む場合でもパスは二重化しない")
    func baseURLAlreadyHasPrefixDoesNotDuplicatePath() async throws {
        clearKeychainState()
        defer { clearKeychainState() }

        setenv("API_BASE_URL", "https://example.com/api/v1", 1)
        setenv("FIREBASE_ID_TOKEN", "token-for-test", 1)
        defer {
            unsetenv("API_BASE_URL")
            unsetenv("FIREBASE_ID_TOKEN")
        }

        URLProtocolStub.reset()
        let tokenResponse = """
        {"ble_token":{"token":"abc123","expires_at":"2026-03-16T00:00:00Z"}}
        """
        URLProtocolStub.handler = { request in
            #expect(request.url?.path == "/api/v1/ble-tokens/current")
            #expect(request.url?.path.contains("/api/v1/api/v1/") == false)
            return HTTPStubResponse(statusCode: 200, body: Data(tokenResponse.utf8))
        }

        let client = BLEBackendClient(session: makeStubSession())
        let token = try await client.fetchOrIssueCurrentToken()
        #expect(token.token == "abc123")
    }

    @Test("恒久エラーは dead-letter へ隔離し、後続エンカウント送信を継続する")
    func permanentFailureMovesToDeadLetterAndContinues() async throws {
        clearKeychainState()
        defer { clearKeychainState() }

        setenv("API_BASE_URL", "https://example.com", 1)
        setenv("FIREBASE_ID_TOKEN", "token-for-test", 1)
        defer {
            unsetenv("API_BASE_URL")
            unsetenv("FIREBASE_ID_TOKEN")
        }

        URLProtocolStub.reset()
        URLProtocolStub.handler = { request in
            guard request.url?.path == "/api/v1/encounters" else {
                return HTTPStubResponse(statusCode: 404, body: Data())
            }

            if URLProtocolStub.recordedRequests.count == 1 {
                return HTTPStubResponse(statusCode: 400, body: Data())
            }
            return HTTPStubResponse(statusCode: 201, body: Data("{}".utf8))
        }

        let client = BLEBackendClient(session: makeStubSession())
        await client.enqueueEncounter(targetBLEToken: "bad-token", rssi: -60, occurredAt: Date())
        await client.enqueueEncounter(targetBLEToken: "good-token", rssi: -58, occurredAt: Date())

        let drained = await waitUntil(timeoutSeconds: 2.0) {
            URLProtocolStub.recordedRequests.count >= 2
        }
        #expect(drained)

        #expect(URLProtocolStub.recordedRequests.count == 2)

        let deadLetters = loadDeadLetters()
        #expect(deadLetters.count == 1)
        #expect(deadLetters.first?.targetBLEToken == "bad-token")
        #expect(deadLetters.first?.statusCode == 400)

        let pending = loadPendingEncounters()
        #expect(pending.isEmpty)
    }
}

private struct HTTPStubResponse {
    let statusCode: Int
    let body: Data
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    static var handler: ((URLRequest) -> HTTPStubResponse)?
    static var recordedRequests: [URLRequest] = []
    private static let lock = NSLock()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lock.lock()
        Self.recordedRequests.append(request)
        let handler = Self.handler
        Self.lock.unlock()

        guard let handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let stub = handler(request)
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: stub.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        recordedRequests = []
        handler = nil
    }
}

private func makeStubSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: config)
}

private func waitUntil(timeoutSeconds: TimeInterval, check: @escaping @Sendable () -> Bool) async -> Bool {
    let deadline = Date().addingTimeInterval(timeoutSeconds)
    while Date() < deadline {
        if check() { return true }
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
    return check()
}

private func clearKeychainState() {
    deleteKeychainValue(for: "ble.pending.encounters.v1")
    deleteKeychainValue(for: "ble.failed.encounters.v1")
}

private func deleteKeychainValue(for key: String) {
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: keychainService(),
        kSecAttrAccount: key
    ]
    SecItemDelete(query as CFDictionary)
}

private func readKeychainValue(for key: String) -> Data? {
    let query: [CFString: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: keychainService(),
        kSecAttrAccount: key,
        kSecReturnData: true,
        kSecMatchLimit: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess else { return nil }
    return item as? Data
}

private func keychainService() -> String {
    Bundle.main.bundleIdentifier ?? "com.digix00.musicswapping.ble"
}

private struct PendingEncounterRecord: Codable {
    let targetBLEToken: String
    let rssi: Int
    let occurredAtEpochMs: Int64
    let attempts: Int
}

private struct FailedEncounterRecord: Codable {
    let targetBLEToken: String
    let rssi: Int
    let occurredAtEpochMs: Int64
    let attempts: Int
    let failedAtEpochMs: Int64
    let statusCode: Int?
    let reason: String
}

private func loadPendingEncounters() -> [PendingEncounterRecord] {
    guard
        let data = readKeychainValue(for: "ble.pending.encounters.v1"),
        let decoded = try? JSONDecoder().decode([PendingEncounterRecord].self, from: data)
    else {
        return []
    }
    return decoded
}

private func loadDeadLetters() -> [FailedEncounterRecord] {
    guard
        let data = readKeychainValue(for: "ble.failed.encounters.v1"),
        let decoded = try? JSONDecoder().decode([FailedEncounterRecord].self, from: data)
    else {
        return []
    }
    return decoded
}
