import SwiftUI

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(PrototypeTheme.accent.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PrototypeTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(PrototypeTheme.success)
        }
        .padding(16)
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
