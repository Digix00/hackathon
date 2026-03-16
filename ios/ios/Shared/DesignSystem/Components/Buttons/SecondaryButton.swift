import SwiftUI

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SecondaryButtonLabel(title: title, systemImage: systemImage)
        }
    }
}

struct SecondaryButtonLabel: View {
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
                .font(PrototypeTheme.Typography.Product.control)
        }
        .foregroundStyle(PrototypeTheme.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(PrototypeTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
