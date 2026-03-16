import SwiftUI

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(PrototypeTheme.textPrimary)
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(PrototypeTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(PrototypeTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
