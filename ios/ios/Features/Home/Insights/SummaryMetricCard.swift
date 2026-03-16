import SwiftUI

struct SummaryMetricCard: View {
    let title: String
    let count: Int
    let zeroMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(PrototypeTheme.textSecondary)
                .kerning(1.0)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(count > 0 ? PrototypeTheme.accent : PrototypeTheme.textPrimary)
                Text("人")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textTertiary)
            }

            if count == 0 {
                Text(zeroMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(count > 0 ? PrototypeTheme.surface : PrototypeTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
