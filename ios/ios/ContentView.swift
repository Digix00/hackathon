import SwiftUI

struct ContentView: View {
    private enum Phase {
        case splash
        case onboarding
        case main
    }

    @State private var phase: Phase = .splash

    var body: some View {
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
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: phase)
        .task {
            guard phase == .splash else { return }
            try? await Task.sleep(for: .milliseconds(900))
            phase = .onboarding
        }
    }
}

#Preview {
    ContentView()
}
