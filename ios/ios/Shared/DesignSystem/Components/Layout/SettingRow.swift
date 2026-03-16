import SwiftUI

struct SettingRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(PrototypeTheme.textTertiary)
        }
        .padding(.vertical, 6)
    }
}
