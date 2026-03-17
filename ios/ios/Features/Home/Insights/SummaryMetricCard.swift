import SwiftUI

struct SummaryMetricCard: View {
    let title: String
    let count: Int
    let zeroMessage: String

    var body: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .tracking(1.5)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(count)")
                        .font(PrototypeTheme.Typography.font(size: 40, weight: .black, role: .data))
                        .foregroundStyle(count > 0 ? PrototypeTheme.accent : PrototypeTheme.textPrimary)
                    Text("人")
                        .font(PrototypeTheme.Typography.font(size: 11, weight: .bold, role: .primary))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }

                if count == 0 {
                    Text(zeroMessage)
                        .font(PrototypeTheme.Typography.font(size: 12, weight: .medium, role: .primary))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .opacity(0.8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
