import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let footnote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(PrototypeTheme.textPrimary)
            Text(footnote)
                .font(.system(size: 12))
                .foregroundStyle(PrototypeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(PrototypeTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
