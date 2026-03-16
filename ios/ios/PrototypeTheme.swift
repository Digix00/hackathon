import SwiftUI

enum PrototypeTheme {
    private static func rgb(_ red: Int, _ green: Int, _ blue: Int) -> Color {
        Color(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }

    static let background = rgb(242, 246, 250)
    static let surface = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let surfaceMuted = rgb(232, 238, 244)
    static let surfaceElevated = rgb(222, 230, 238)
    static let textPrimary = rgb(15, 23, 42)
    static let textSecondary = rgb(100, 116, 139)
    static let textTertiary = rgb(148, 163, 184)
    static let accent = rgb(51, 65, 85)
    static let border = rgb(226, 232, 240)
    static let success = rgb(22, 163, 74)
    static let warning = rgb(202, 138, 4)
    static let error = rgb(220, 38, 38)
    static let info = rgb(37, 99, 235)

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

struct AppScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    let trailingSymbol: String?
    let accentColor: Color?
    @ViewBuilder var content: Content
    
    @Environment(\.topSafeAreaInset) private var envTopSafeArea
    @Environment(\.bottomSafeAreaInset) private var envBottomSafeArea

    init(
        title: String,
        subtitle: String? = nil,
        trailingSymbol: String? = nil,
        accentColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailingSymbol = trailingSymbol
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let topPadding = (envTopSafeArea > 0 ? envTopSafeArea : geometry.safeAreaInsets.top)
            let bottomPadding = (envBottomSafeArea > 0 ? envBottomSafeArea : geometry.safeAreaInsets.bottom)

            ZStack {
                if let accentColor {
                    DynamicBackground(baseColor: accentColor)
                } else {
                    ZStack {
                        PrototypeTheme.background.ignoresSafeArea()
                        DotGridBackground()
                            .opacity(0.15)
                    }
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(title)
                                    .font(PrototypeTheme.Typography.Product.screenTitle)
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .tracking(-0.5)

                                if let subtitle {
                                    Text(subtitle)
                                        .font(PrototypeTheme.Typography.Product.subtitle)
                                        .foregroundStyle(PrototypeTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(PrototypeTheme.surfaceMuted.opacity(0.6))
                                        .clipShape(Capsule())
                                }
                            }
                            Spacer()
                            if let trailingSymbol {
                                Button(action: {}) {
                                    Image(systemName: trailingSymbol)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(PrototypeTheme.textPrimary)
                                        .padding(12)
                                        .background(PrototypeTheme.surface)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                                }
                            }
                        }
                        .padding(.top, topPadding + 8)

                        content
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(24, bottomPadding + 8))
                }
                .scrollContentBackground(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Color.clear)
            .ignoresSafeArea()
        }
    }
}

struct DynamicBackground: View {
    let baseColor: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            PrototypeTheme.background.ignoresSafeArea()

            // Deep Layer Blob
            Circle()
                .fill(baseColor.opacity(0.18))
                .frame(width: 650, height: 650)
                .offset(x: animate ? 60 : -60, y: animate ? -120 : 120)
                .blur(radius: 90)

            // Dynamic Accent Blob
            Circle()
                .fill(baseColor.opacity(0.15))
                .frame(width: 450, height: 450)
                .offset(x: animate ? -140 : 140, y: animate ? 170 : -70)
                .blur(radius: 110)
            
            // Texture overlay
            DotGridBackground()
                .opacity(0.25)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
        .ignoresSafeArea()
    }
}

struct DotGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let dotSize: CGFloat = 1.0
            let spacing: CGFloat = 28
            
            for x in stride(from: spacing/2, through: size.width, by: spacing) {
                for y in stride(from: spacing/2, through: size.height, by: spacing) {
                    let rect = CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(PrototypeTheme.textSecondary.opacity(0.15)))
                }
            }
        }
        .ignoresSafeArea()
    }
}

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

struct GlassmorphicCard<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.1), .white.opacity(0.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 24, x: 0, y: 12)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(PrototypeTheme.Typography.Product.control)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isDisabled ? PrototypeTheme.textTertiary : PrototypeTheme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isDisabled)
    }
}

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

struct MockArtworkView: View {
    let color: Color
    let symbol: String
    var size: CGFloat = 56

    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.95), color.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.28, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
    }
}

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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Safe Area Environment Keys

private struct TopSafeAreaInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

private struct BottomSafeAreaInsetKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var topSafeAreaInset: CGFloat {
        get { self[TopSafeAreaInsetKey.self] }
        set { self[TopSafeAreaInsetKey.self] = newValue }
    }

    var bottomSafeAreaInset: CGFloat {
        get { self[BottomSafeAreaInsetKey.self] }
        set { self[BottomSafeAreaInsetKey.self] = newValue }
    }
}
