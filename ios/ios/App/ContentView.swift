import SwiftUI

struct ContentView: View {
    private enum Phase {
        case splash
        case onboarding
        case main
    }

    @State private var phase: Phase = .splash

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
            phase = .main
        }
    }

    @ViewBuilder
    private func phaseView(using proxy: GeometryProxy) -> some View {
        switch phase {
        case .splash:
            SplashScreenView()
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
}
