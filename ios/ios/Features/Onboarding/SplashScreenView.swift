import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PrototypeTheme.background, PrototypeTheme.surfaceMuted],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(PrototypeTheme.surface)
                        .frame(width: 104, height: 104)
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                }

                Text("すれ違い趣味交換")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                Text("街を歩くだけで、誰かの音楽と出会える")
                    .font(.system(size: 15))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            .padding(24)
        }
    }
}
