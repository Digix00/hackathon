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
            let topSafeArea = proxy.safeAreaInsets.top
            let bottomSafeArea = proxy.safeAreaInsets.bottom

            ZStack {
                PrototypeTheme.background.ignoresSafeArea()

                if phase == .splash {
                    SplashScreenView()
                        .transition(.opacity)
                } else if phase == .main {
                    MainPrototypeView(
                        restartOnboarding: { phase = .onboarding }
                    )
                    .transition(.opacity)
                } else {
                    OnboardingFlowView(
                        onFinish: { phase = .main }
                    )
                    .environment(\.topSafeAreaInset, topSafeArea)
                    .environment(\.bottomSafeAreaInset, bottomSafeArea)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: phase)
            .ignoresSafeArea()
        }
        .task {
            guard phase == .splash else { return }
            try? await Task.sleep(for: .milliseconds(900))
            phase = .onboarding
        }
    }
}
