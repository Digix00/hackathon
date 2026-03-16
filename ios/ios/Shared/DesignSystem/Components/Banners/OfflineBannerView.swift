import SwiftUI

struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(PrototypeTheme.warning)

            Text("オフライン")
                .prototypeFont(size: 12, weight: .black, role: .data)
                .foregroundStyle(PrototypeTheme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(PrototypeTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
