import SwiftUI

extension PrototypeTheme {
    enum Typography {
        enum Role {
            case primary
            case accent
            case data

            var design: Font.Design {
                switch self {
                case .primary:
                    return .rounded
                case .accent:
                    return .serif
                case .data:
                    return .monospaced
                }
            }
        }

        static func font(
            size: CGFloat,
            weight: Font.Weight = .regular,
            role: Role = .primary
        ) -> Font {
            .system(size: size, weight: weight, design: role.design)
        }

        enum Encounter {
            static let screenTitle = Typography.font(size: 28, weight: .bold)
            static let sectionTitle = Typography.font(size: 18, weight: .semibold)
            static let cardTitle = Typography.font(size: 16, weight: .semibold)
            static let body = Typography.font(size: 14, weight: .medium)
            static let meta = Typography.font(size: 13, weight: .medium)
            static let metaCompact = Typography.font(size: 12, weight: .semibold)
            static let action = Typography.font(size: 14, weight: .bold)
            static let eyebrow = Typography.font(size: 11, weight: .bold)
        }

        enum Product {
            static let screenTitle = Typography.font(size: 32, weight: .black)
            static let subtitle = Typography.font(size: 14, weight: .medium)
            static let sectionLabel = Typography.font(size: 13, weight: .semibold)
            static let control = Typography.font(size: 16, weight: .semibold)
        }

        enum Onboarding {
            static let title = Typography.font(size: 32, weight: .black)
            static let body = Typography.font(size: 16, weight: .medium)
            static let eyebrow = Typography.font(size: 12, weight: .black)
            static let cardLabel = Typography.font(size: 10, weight: .black)
            static let button = Typography.font(size: 16, weight: .semibold)
            static let stepTitle = Typography.font(size: 32, weight: .black)
            static let stepSubtitle = Typography.font(size: 12, weight: .black)
        }
    }
}
