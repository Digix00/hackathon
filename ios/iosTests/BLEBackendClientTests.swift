import Foundation
import XCTest
@testable import ios

final class BLEBackendClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("FIREBASE_ID_TOKEN", "test-token", 1)
        setenv("API_BASE_URL", "https://example.test", 1)
        BLEBackendClientMockURLProtocol.requestHandler = nil
        BLEBackendClientMockURLProtocol.lastRequest = nil
    }

    override func tearDown() {
        unsetenv("FIREBASE_ID_TOKEN")
        unsetenv("API_BASE_URL")
        BLEBackendClientMockURLProtocol.requestHandler = nil
        BLEBackendClientMockURLProtocol.lastRequest = nil
        super.tearDown()
    }

    func testPostEncounterAcceptsNoContentResponse() async throws {
        let client = BLEBackendClient(session: makeSession())

        BLEBackendClientMockURLProtocol.requestHandler = { request in
            BLEBackendClientMockURLProtocol.lastRequest = request
            return (204, Data())
        }

        try await client.postEncounter(
            targetBLEToken: "b2f2f0fa3c1d9e77",
            rssi: -85,
            occurredAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let request = try XCTUnwrap(BLEBackendClientMockURLProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertTrue(request.url?.path.hasSuffix("/api/v1/encounters") == true)
    }

    func testPostEncounterThrowsOnUnexpectedStatus() async throws {
        let client = BLEBackendClient(session: makeSession())

        BLEBackendClientMockURLProtocol.requestHandler = { request in
            BLEBackendClientMockURLProtocol.lastRequest = request
            return (400, Data())
        }

        do {
            try await client.postEncounter(
                targetBLEToken: "b2f2f0fa3c1d9e77",
                rssi: -70,
                occurredAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
            XCTFail("Expected postEncounter to throw on 400 response")
        } catch let error as BLEBackendClient.BackendError {
            switch error {
            case .unexpectedStatus(let statusCode):
                XCTAssertEqual(statusCode, 400)
            default:
                XCTFail("Expected unexpectedStatus, got \(error)")
            }
        }
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [BLEBackendClientMockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

private final class BLEBackendClientMockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) -> (Int, Data))?
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let (statusCode, data) = handler(request)
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.test")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
