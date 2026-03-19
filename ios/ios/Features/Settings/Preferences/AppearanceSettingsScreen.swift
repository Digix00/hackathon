import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var settingsViewModel: UserSettingsViewModel

    var body: some View {
        AppScaffold(
            title: "外観",
            subtitle: "VISUAL INTERFACE",
            showsBackButton: true
        ) {
            VStack(alignment: .leading, spacing: 56) {
                VStack(alignment: .leading, spacing: 32) {
                    HStack {
                        Text("INTERFACE THEME")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.5)
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                        Spacer()
                        Text("UI-MODE")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.5))
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            themeCard(for: .light, fullWidth: true)
                            themeCard(for: .dark, fullWidth: true)
                        }

                        themeCard(for: .system, fullWidth: true)
                    }
                }

                if settingsViewModel.isLoading || settingsViewModel.isSaving || settingsViewModel.errorMessage != nil {
                    SettingsStatusView(
                        isLoading: settingsViewModel.isLoading && !settingsViewModel.hasLoaded,
                        isSaving: settingsViewModel.isSaving,
                        errorMessage: settingsViewModel.errorMessage
                    )
                    .padding(.horizontal, 8)
                }

                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(PrototypeTheme.accent.opacity(0.5))
                        Text("DESIGN GUIDELINE")
                            .prototypeFont(size: 10, weight: .black, role: .data)
                            .kerning(2.5)
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                    }

                    Text("Urban Serendipity は、時間帯や周囲の環境に合わせた動的な背景演出を採用しています。システム設定に従うことで、より没入感のある体験が可能です。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .lineSpacing(6)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(PrototypeTheme.surfaceMuted.opacity(0.2))
                )
                .padding(.bottom, 60)
            }
            .disabled(settingsViewModel.isSaving)
            .onAppear { settingsViewModel.loadIfNeeded() }
        }
    }

    private func themeCard(for mode: UserSettingsViewModel.ThemeMode, fullWidth: Bool) -> some View {
        let isSelected = settingsViewModel.themeMode == mode

        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                settingsViewModel.setThemeMode(mode)
            }
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? .white.opacity(0.2) : PrototypeTheme.surfaceMuted.opacity(0.5))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: iconName(for: mode))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(isSelected ? .white : PrototypeTheme.accent)
                }

                Text(title(for: mode))
                    .prototypeFont(size: 11, weight: .black, role: .data)
                    .kerning(1.5)
                    .foregroundStyle(isSelected ? .white : PrototypeTheme.textSecondary)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(isSelected ? PrototypeTheme.accent : PrototypeTheme.surface.opacity(0.4))
                    .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.02), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(PrototypeTheme.border.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func title(for mode: UserSettingsViewModel.ThemeMode) -> String {
        switch mode {
        case .light:
            return "LIGHT"
        case .dark:
            return "DARK"
        case .system:
            return "AUTO"
        }
    }

    private func iconName(for mode: UserSettingsViewModel.ThemeMode) -> String {
        switch mode {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "desktopcomputer"
        }
    }
}
