import XCTest
@testable import ios

@MainActor
final class AuthSessionTests: XCTestCase {
    func test_init_whenFirebaseNotConfigured_setsSignedOut() throws {
#if canImport(FirebaseAuth) && canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            let session = AuthSession()
            XCTAssertEqual(session.status, .signedOut)
        } else {
            throw XCTSkip("FirebaseApp is configured; skipping non-configured case")
        }
#else
        let session = AuthSession()
        XCTAssertEqual(session.status, .signedOut)
#endif
    }

#if canImport(FirebaseAuth) && canImport(FirebaseCore)
    func test_listener_updatesStatus_onAuthChange() async throws {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        guard FirebaseApp.app() != nil else {
            throw XCTSkip("Firebase not configured; skip listener test")
        }

        try? Auth.auth().signOut()
        let session = AuthSession()
        XCTAssertEqual(session.status, .signedOut)

        // Sign in anonymously and wait for listener to update
        _ = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error { cont.resume(throwing: error); return }
                if let ar = authResult { cont.resume(returning: ar); return }
                cont.resume(throwing: NSError(domain: "Auth", code: -1))
            }
        }

        // wait for session.status to become signedIn
        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline && session.status != .signedIn {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertEqual(session.status, .signedIn)

        // Sign out and expect signedOut
        try Auth.auth().signOut()
        let deadline2 = Date().addingTimeInterval(5)
        while Date() < deadline2 && session.status != .signedOut {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertEqual(session.status, .signedOut)
    }
#endif
}
