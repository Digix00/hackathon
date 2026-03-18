import Foundation
import XCTest
@testable import ios

final class BackendAPIClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("FIREBASE_ID_TOKEN", "test-token", 1)
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.lastRequest = nil
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.lastRequest = nil
        super.tearDown()
    }

    func testCreateEncounterSendsExpectedPayload() async throws {
        let session = makeSession()
        let client = BackendAPIClient(session: session)

        let occurredAt = Date(timeIntervalSince1970: 1_700_000_000)

        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.lastRequest = request
            let responseBody = """
            {
              "encounter": {
                "id": "enc-1",
                "type": "ble",
                "user": { "id": "user-1", "display_name": "mio", "avatar_url": null },
                "occurred_at": "2026-03-15T10:00:00Z"
              }
            }
            """
            return (200, Data(responseBody.utf8))
        }

        let result = try await client.createEncounter(
            CreateEncounterRequest(
                targetBleToken: "b2f2f0fa3c1d9e77",
                type: "ble",
                rssi: -42,
                occurredAt: occurredAt
            )
        )

        let request = try XCTUnwrap(MockURLProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertTrue(request.url?.path.hasSuffix("/api/v1/encounters") == true)
        XCTAssertEqual(result?.id, "enc-1")

        let body = try XCTUnwrap(request.httpBody)
        let payload = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(payload["target_ble_token"] as? String, "b2f2f0fa3c1d9e77")
        XCTAssertEqual(payload["type"] as? String, "ble")
        XCTAssertEqual(payload["rssi"] as? Int, -42)
        XCTAssertNotNil(payload["occurred_at"])
    }

    func testListEncountersUsesCursorAndLimit() async throws {
        let session = makeSession()
        let client = BackendAPIClient(session: session)

        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.lastRequest = request
            let responseBody = """
            {
              "encounters": [
                {
                  "id": "enc-1",
                  "type": "ble",
                  "user": { "id": "user-1", "display_name": "mio", "avatar_url": null },
                  "is_read": false,
                  "tracks": [
                    { "id": "spotify:track:1", "title": "Song", "artist_name": "Artist", "artwork_url": null, "preview_url": null }
                  ],
                  "occurred_at": "2026-03-15T10:00:00Z"
                }
              ],
              "pagination": { "next_cursor": "next-1", "has_more": true }
            }
            """
            return (200, Data(responseBody.utf8))
        }

        let response = try await client.listEncounters(limit: 1, cursor: "cursor-1")
        XCTAssertEqual(response.encounters.count, 1)
        XCTAssertEqual(response.pagination.nextCursor, "next-1")
        XCTAssertTrue(response.pagination.hasMore)

        let request = try XCTUnwrap(MockURLProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url?.path.hasSuffix("/api/v1/encounters") == true)
        let query = request.url?.query ?? ""
        XCTAssertTrue(query.contains("limit=1"))
        XCTAssertTrue(query.contains("cursor=cursor-1"))
    }

    func testGetEncounterByID() async throws {
        let session = makeSession()
        let client = BackendAPIClient(session: session)

        MockURLProtocol.requestHandler = { request in
            MockURLProtocol.lastRequest = request
            let responseBody = """
            {
              "encounter": {
                "id": "enc-2",
                "type": "location",
                "user": { "id": "user-2", "display_name": "kai", "avatar_url": null },
                "occurred_at": "2026-03-16T12:00:00Z",
                "tracks": []
              }
            }
            """
            return (200, Data(responseBody.utf8))
        }

        let encounter = try await client.getEncounterByID(id: "enc-2")
        XCTAssertEqual(encounter.id, "enc-2")

        let request = try XCTUnwrap(MockURLProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url?.path.hasSuffix("/api/v1/encounters/enc-2") == true)
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

private final class MockURLProtocol: URLProtocol {
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
            url: request.url ?? URL(string: "http://localhost")!,
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
