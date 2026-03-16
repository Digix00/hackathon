import SwiftUI

extension View {
    func prototypeTypography() -> some View {
        fontDesign(PrototypeTheme.Typography.Role.primary.design)
    }

    func prototypeFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        role: PrototypeTheme.Typography.Role = .primary
    ) -> some View {
        font(PrototypeTheme.Typography.font(size: size, weight: weight, role: role))
    }
}
