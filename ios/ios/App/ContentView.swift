import SwiftUI

struct ContentView: View {
    private enum Phase {
        case splash
        case auth
        case onboarding
        case main
    }

    @State private var phase: Phase = .splash
    @StateObject private var authSession = AuthSession()
    private let userClient: BackendUserAPIClient = BackendAPIClient()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PrototypeTheme.background.ignoresSafeArea()
                phaseView(using: proxy)
                    .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.25), value: phase)
            .ignoresSafeArea()
        }
        .task {
            authSession.startIfNeeded()
            guard phase == .splash else { return }
            try? await Task.sleep(for: .milliseconds(900))
            await updatePhaseAfterSplash()
        }
        .onChange(of: authSession.status) { _, newStatus in
            guard phase != .splash else { return }
            Task {
                await handleAuthStatusChange(newStatus)
            }
        }
    }

    @ViewBuilder
    private func phaseView(using proxy: GeometryProxy) -> some View {
        switch phase {
        case .splash:
            SplashScreenView()
        case .auth:
            AuthGateView()
                .environmentObject(authSession)
        case .onboarding:
            OnboardingFlowView(
                onFinish: { phase = .main }
            )
            .environment(\.topSafeAreaInset, proxy.safeAreaInsets.top)
            .environment(\.bottomSafeAreaInset, proxy.safeAreaInsets.bottom)
        case .main:
            MainPrototypeView(
                restartOnboarding: { phase = .onboarding }
            )
            .environmentObject(authSession)
        }
    }

    @MainActor
    private func handleAuthStatusChange(_ status: AuthSession.Status) async {
        switch status {
        case .signedIn:
            phase = .splash
            phase = await initialSignedInPhase()
        case .signedOut:
            phase = .auth
        case .checking:
            break
        }
    }

    private func updatePhaseAfterSplash() async {
        if authSession.status == .signedIn {
            phase = await initialSignedInPhase()
        } else {
            phase = .auth
        }
    }

    private func initialSignedInPhase() async -> Phase {
        do {
            _ = try await userClient.getMe()
            return .main
        } catch let error as BackendAPIClient.BackendError {
            switch error {
            case .unexpectedStatus(let code, _) where code == 404:
                return .onboarding
            case .missingAuthToken, .invalidBaseURL:
                return .auth
            default:
                // Existing signed-in users should not be forced through onboarding
                // just because profile prefetch failed transiently.
                return .main
            }
        } catch {
            return .main
        }
    }
}
