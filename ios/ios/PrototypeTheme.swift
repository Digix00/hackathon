import SwiftUI

enum PrototypeTheme {
    static let background = Color(red: 242 / 255, green: 246 / 255, blue: 250 / 255)
    static let surface = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let surfaceMuted = Color(red: 232 / 255, green: 238 / 255, blue: 244 / 255)
    static let surfaceElevated = Color(red: 222 / 255, green: 230 / 255, blue: 238 / 255)
    static let textPrimary = Color(red: 15 / 255, green: 23 / 255, blue: 42 / 255)
    static let textSecondary = Color(red: 100 / 255, green: 116 / 255, blue: 139 / 255)
    static let textTertiary = Color(red: 148 / 255, green: 163 / 255, blue: 184 / 255)
    static let accent = Color(red: 71 / 255, green: 85 / 255, blue: 105 / 255)
    static let border = Color(red: 226 / 255, green: 232 / 255, blue: 240 / 255)
    static let success = Color(red: 22 / 255, green: 163 / 255, blue: 74 / 255)
    static let warning = Color(red: 202 / 255, green: 138 / 255, blue: 4 / 255)
    static let error = Color(red: 220 / 255, green: 38 / 255, blue: 38 / 255)
    static let info = Color(red: 37 / 255, green: 99 / 255, blue: 235 / 255)
}

struct AppScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    let trailingSymbol: String?
    let accentColor: Color?
    @ViewBuilder var content: Content

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
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .tracking(-0.5)
                            
                            if let subtitle {
                                Text(subtitle)
                                    .font(.system(size: 15, weight: .medium))
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
                    .padding(.top, 12)

                    content
                }
                .padding(24)
            }
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
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .textCase(.uppercase)
                    .kerning(1.2)
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
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(PrototypeTheme.border.opacity(0.5), lineWidth: 1)
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
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
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
                    .font(.system(size: 16, weight: .semibold))
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
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(PrototypeTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(PrototypeTheme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
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
