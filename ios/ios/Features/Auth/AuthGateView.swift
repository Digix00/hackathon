import AuthenticationServices
import Combine
import CryptoKit
import Security
import SwiftUI
import UIKit

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

struct AuthGateView: View {
    @StateObject private var viewModel = AuthGateViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PrototypeTheme.background, PrototypeTheme.surfaceMuted, PrototypeTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                hero

                VStack(spacing: 14) {
                    SignInWithAppleButton(.continue) { request in
                        viewModel.prepareAppleRequest(request)
                    } onCompletion: { result in
                        viewModel.handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(viewModel.isLoading)

                    Button(action: viewModel.signInWithGoogle) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Google で続ける")
                                .font(PrototypeTheme.Typography.Product.control)
                        }
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(PrototypeTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PrototypeTheme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(viewModel.isLoading)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                        .multilineTextAlignment(.center)
                } else {
                    Text("ログイン後にプロフィールと権限設定へ進みます。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                footer
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)

            if viewModel.isLoading {
                Color.black.opacity(0.12)
                    .ignoresSafeArea()

                ProgressView()
                    .controlSize(.large)
                    .tint(PrototypeTheme.textPrimary)
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(PrototypeTheme.surface)
                    .frame(width: 124, height: 124)

                Circle()
                    .stroke(PrototypeTheme.border, lineWidth: 1)
                    .frame(width: 160, height: 160)

                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textPrimary)
            }
            .padding(.bottom, 8)

            VStack(spacing: 12) {
                Text("MUSIC SWAPPING")
                    .font(PrototypeTheme.Typography.Onboarding.eyebrow)
                    .foregroundStyle(PrototypeTheme.accent)
                    .kerning(2.4)

                Text("ログインして、\n出会いの入口へ。")
                    .font(PrototypeTheme.Typography.Onboarding.title)
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)

                Text("Apple または Google でサインインしてから、オンボーディングを開始します。")
                    .font(PrototypeTheme.Typography.Onboarding.body)
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Text("Apple は Firebase Auth の `apple.com`、Google は `GoogleSignIn` と Firebase Credential を使用します。")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PrototypeTheme.textTertiary)
                .multilineTextAlignment(.center)

            Text("Google ログインには `GoogleService-Info.plist` または `Secrets.xcconfig` の設定と URL Scheme が必要です。")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PrototypeTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
}

@MainActor
final class AuthGateViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentNonce: String?

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        errorMessage = nil
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await signInWithApple(result)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signInWithGoogle() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await signInUsingGoogle()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func signInWithApple(_ result: Result<ASAuthorization, Error>) async throws {
#if canImport(FirebaseAuth)
        let authorization: ASAuthorization
        switch result {
        case .success(let value):
            authorization = value
        case .failure(let error):
            throw error
        }

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthGateError.invalidAppleCredential
        }
        guard let nonce = currentNonce else {
            throw AuthGateError.missingNonce
        }
        guard
            let tokenData = appleIDCredential.identityToken,
            let tokenString = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthGateError.invalidAppleToken
        }

        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: tokenString,
            rawNonce: nonce
        )
        _ = try await signInToFirebase(with: credential)
#else
        throw AuthGateError.firebaseUnavailable
#endif
    }

    private func signInUsingGoogle() async throws {
#if canImport(FirebaseAuth) && canImport(GoogleSignIn)
        guard let clientID = resolvedGoogleClientID() else {
            throw AuthGateError.missingGoogleClientID
        }
        guard let presentingViewController = UIApplication.topViewController() else {
            throw AuthGateError.missingPresentingViewController
        }

        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthGateError.missingGoogleIDToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        _ = try await signInToFirebase(with: credential)
#elseif canImport(FirebaseAuth)
        throw AuthGateError.googleSignInUnavailable
#else
        throw AuthGateError.firebaseUnavailable
#endif
    }

#if canImport(FirebaseAuth)
    private func signInToFirebase(with credential: AuthCredential) async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result else {
                    continuation.resume(throwing: AuthGateError.emptyFirebaseResult)
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
#endif

    private func resolvedGoogleClientID() -> String? {
#if canImport(FirebaseCore)
        if let clientID = FirebaseApp.app()?.options.clientID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !clientID.isEmpty {
            return clientID
        }
#endif

        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String {
            let trimmed = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }

        return nil
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if status != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
                }
                return random
            }

            randoms.forEach { random in
                guard remainingLength > 0 else { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
}

private enum AuthGateError: LocalizedError {
    case invalidAppleCredential
    case missingNonce
    case invalidAppleToken
    case missingGoogleClientID
    case missingGoogleIDToken
    case missingPresentingViewController
    case googleSignInUnavailable
    case firebaseUnavailable
    case emptyFirebaseResult

    var errorDescription: String? {
        switch self {
        case .invalidAppleCredential:
            return "Apple ログイン情報を取得できませんでした。"
        case .missingNonce:
            return "Apple ログインの nonce が失われました。再試行してください。"
        case .invalidAppleToken:
            return "Apple の ID トークンを読み取れませんでした。"
        case .missingGoogleClientID:
            return "Google Client ID が未設定です。Firebase 設定を確認してください。"
        case .missingGoogleIDToken:
            return "Google の ID トークンを取得できませんでした。"
        case .missingPresentingViewController:
            return "ログイン画面を表示する ViewController を取得できませんでした。"
        case .googleSignInUnavailable:
            return "GoogleSignIn パッケージが未導入です。"
        case .firebaseUnavailable:
            return "Firebase Auth が未導入です。"
        case .emptyFirebaseResult:
            return "Firebase の認証結果が空でした。"
        }
    }
}

private extension UIApplication {
    static func topViewController(
        base: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    ) -> UIViewController? {
        if let navigationController = base as? UINavigationController {
            return topViewController(base: navigationController.visibleViewController)
        }
        if let tabBarController = base as? UITabBarController, let selected = tabBarController.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
