import SwiftUI

enum PrototypeTheme {
    static let background = Color(red: 248 / 255, green: 250 / 255, blue: 252 / 255)
    static let surface = Color.white
    static let surfaceMuted = Color(red: 241 / 255, green: 245 / 255, blue: 249 / 255)
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
    let trailingSymbol: String?
    @ViewBuilder var content: Content

    init(
        title: String,
        trailingSymbol: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.trailingSymbol = trailingSymbol
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                    Spacer()
                    if let trailingSymbol {
                        Image(systemName: trailingSymbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                }

                content
            }
            .padding(20)
        }
        .background(PrototypeTheme.background)
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
        VStack(alignment: .leading, spacing: 16) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PrototypeTheme.border, lineWidth: 1)
        )
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
            .background(PrototypeTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(PrototypeTheme.border, lineWidth: 1)
            )
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
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PrototypeTheme.border, lineWidth: 1)
        )
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
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PrototypeTheme.border, lineWidth: 1)
        )
    }
}
