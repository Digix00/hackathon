import AuthenticationServices
#if canImport(UIKit)
import UIKit
#endif

/// Spotify などの OAuth フローを ASWebAuthenticationSession で処理するコーディネーター。
/// openURL の代わりに使うことで、Spotify アプリがインストールされていても
/// ユニバーサルリンクによるインターセプトを防ぎ、Safari View Controller を強制使用する。
@MainActor
final class OAuthSessionCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthSessionCoordinator()

    private var activeSession: ASWebAuthenticationSession?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func start(url: URL, callbackScheme: String, completion: @escaping @MainActor (URL?) -> Void) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, _ in
            Task { @MainActor in
                self?.activeSession = nil
                completion(callbackURL)
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        activeSession = session
        session.start()
    }
}
