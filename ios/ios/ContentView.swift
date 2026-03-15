import SwiftUI

struct ContentView: View {
    @State private var showsSplash = true
    @State private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            PrototypeTheme.background.ignoresSafeArea()

            if showsSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else if hasCompletedOnboarding {
                MainPrototypeView(
                    restartOnboarding: { hasCompletedOnboarding = false }
                )
                .transition(.opacity)
            } else {
                OnboardingFlowView(
                    onFinish: { hasCompletedOnboarding = true }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showsSplash)
        .animation(.easeInOut(duration: 0.25), value: hasCompletedOnboarding)
        .task {
            guard showsSplash else { return }
            try? await Task.sleep(for: .milliseconds(900))
            showsSplash = false
        }
    }
}

#Preview {
    ContentView()
}
