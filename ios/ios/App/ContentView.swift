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
            guard phase == .splash else { return }
            try? await Task.sleep(for: .milliseconds(900))
            updatePhaseAfterSplash()
        }
        .onChange(of: authSession.status) { _, newStatus in
            guard phase != .splash else { return }

            switch newStatus {
            case .signedIn:
                if phase == .auth {
                    phase = .onboarding
                }
            case .signedOut:
                phase = .auth
            case .checking:
                break
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
        }
    }

    private func updatePhaseAfterSplash() {
        phase = authSession.status == .signedIn ? .onboarding : .auth
    }
}
