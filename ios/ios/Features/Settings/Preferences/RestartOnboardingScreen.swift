import SwiftUI

struct RestartOnboardingView: View {
    let restartOnboarding: () -> Void

    var body: some View {
        AppScaffold(
            title: "オンボーディング再表示",
            subtitle: "最初の案内をやり直す"
        ) {
            VStack(spacing: 28) {
                EmptyStateCard(
                    icon: "sparkles",
                    title: "最初から確認し直せます",
                    message: "設定フローをもう一度表示します。",
                    tint: PrototypeTheme.accent
                )

                PrimaryButton(title: "オンボーディングを再表示", systemImage: "arrow.counterclockwise") {
                    restartOnboarding()
                }
            }
        }
    }
}
