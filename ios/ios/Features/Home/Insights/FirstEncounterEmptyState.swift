import SwiftUI

struct FirstEncounterEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            EmptyStateCard(
                icon: "figure.walk",
                title: "まだすれ違いがありません",
                message: "最初の出会いを待っています。",
                tint: PrototypeTheme.accent
            )
        }
    }
}
