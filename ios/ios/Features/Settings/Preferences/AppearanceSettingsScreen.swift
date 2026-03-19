import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var settingsViewModel: UserSettingsViewModel

    var body: some View {
        AppScaffold(
            title: "外観",
            subtitle: "VISUAL INTERFACE"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("INTERFACE THEME")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Spacer()
                        Text("UI-MODE")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                    }
                    .padding(.horizontal, 4)

                    HStack(spacing: 16) {
                        themeCard(for: .light, fullWidth: false)
                        themeCard(for: .dark, fullWidth: false)
                    }

                    themeCard(for: .system, fullWidth: true)
                }

                if settingsViewModel.isLoading || settingsViewModel.isSaving || settingsViewModel.errorMessage != nil {
                    SettingsStatusView(
                        isLoading: settingsViewModel.isLoading && !settingsViewModel.hasLoaded,
                        isSaving: settingsViewModel.isSaving,
                        errorMessage: settingsViewModel.errorMessage
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "paintbrush.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(PrototypeTheme.accent)
                        Text("DESIGN GUIDELINE")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }

                    Text("Urban Serendipity は、時間帯や周囲の環境に合わせた動的な背景演出を採用しています。システム設定に従うことで、より没入感のある体験が可能です。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(PrototypeTheme.surfaceMuted.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(settingsViewModel.isSaving)
            .onAppear { settingsViewModel.loadIfNeeded() }
        }
    }

    private func themeCard(for mode: UserSettingsViewModel.ThemeMode, fullWidth: Bool) -> some View {
        let isSelected = settingsViewModel.themeMode == mode

        return Button {
            settingsViewModel.setThemeMode(mode)
        } label: {
            VStack(spacing: 12) {
                Image(systemName: iconName(for: mode))
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .white : PrototypeTheme.accent)

                Text(title(for: mode))
                    .prototypeFont(size: 10, weight: .black, role: .data)
                    .kerning(1.5)
                    .foregroundStyle(isSelected ? .white : PrototypeTheme.textSecondary)
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? PrototypeTheme.accent : PrototypeTheme.surface)
                    .shadow(color: Color.black.opacity(isSelected ? 0.2 : 0.05), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(PrototypeTheme.border, lineWidth: isSelected ? 0 : 1)
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
            return "SYSTEM DEFAULT (AUTO)"
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
