import XCTest
@testable import ios

@MainActor
final class SearchViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setenv("FIREBASE_ID_TOKEN", "test-token", 1)
        SearchMockURLProtocol.requestHandler = nil
        SearchMockURLProtocol.lastRequest = nil
    }

    override func tearDown() {
        unsetenv("FIREBASE_ID_TOKEN")
        SearchMockURLProtocol.requestHandler = nil
        SearchMockURLProtocol.lastRequest = nil
        super.tearDown()
    }

    func testSearchUpdatesStateOnSuccess() async throws {
        let session = makeSession()
        let client = BackendAPIClient(session: session)
        let viewModel = SearchViewModel(client: client)
        viewModel.query = "mio"

        SearchMockURLProtocol.requestHandler = { request in
            SearchMockURLProtocol.lastRequest = request
            let responseBody = """
            {
              "tracks": [
                {
                  "id": "trk-1",
                  "title": "Song",
                  "artist_name": "Artist",
                  "artwork_url": null,
                  "preview_url": null
                }
              ],
              "pagination": { "next_cursor": null, "has_more": false }
            }
            """
            return (200, Data(responseBody.utf8))
        }

        viewModel.search()

        await waitFor { viewModel.isSearching }
        await waitFor { !viewModel.isSearching }

        XCTAssertEqual(viewModel.results.count, 1)
        XCTAssertEqual(viewModel.results.first?.backendId, "trk-1")
        XCTAssertNil(viewModel.errorMessage)

        let request = try XCTUnwrap(SearchMockURLProtocol.lastRequest)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(request.url?.path.hasSuffix("/api/v1/tracks/search") == true)
        XCTAssertTrue(request.url?.query?.contains("q=mio") == true)
    }

    func testSearchSetsErrorOnFailure() async {
        let session = makeSession()
        let client = BackendAPIClient(session: session)
        let viewModel = SearchViewModel(client: client)
        viewModel.query = "mio"

        SearchMockURLProtocol.requestHandler = { request in
            SearchMockURLProtocol.lastRequest = request
            return (500, Data("{ \"error\": \"boom\" }".utf8))
        }

        viewModel.search()

        await waitFor { viewModel.errorMessage != nil }
        XCTAssertEqual(viewModel.errorMessage, "検索に失敗しました")
    }

    private func waitFor(
        timeout: TimeInterval = 1.0,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("Timed out waiting for condition")
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SearchMockURLProtocol.self]
        return URLSession(configuration: config)
    }
}

private final class SearchMockURLProtocol: URLProtocol {
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
