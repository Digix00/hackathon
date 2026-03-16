import SwiftUI

struct SectionCard<Content: View>: View {
    let title: String?
    @ViewBuilder var content: Content

    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let title {
                Text(title)
                    .font(PrototypeTheme.Typography.Product.sectionLabel)
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .tracking(0.2)
            }
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(PrototypeTheme.surface)
                .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 8)
        )
    }
}
