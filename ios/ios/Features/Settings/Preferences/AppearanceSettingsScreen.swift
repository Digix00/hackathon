import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var settingsViewModel: UserSettingsViewModel

    var body: some View {
        AppScaffold(
            title: "外観",
            subtitle: "表示テーマの設定"
        ) {
            VStack(spacing: 24) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(UserSettingsViewModel.ThemeMode.allCases) { mode in
                            Button {
                                settingsViewModel.setThemeMode(mode)
                            } label: {
                                HStack(spacing: 12) {
                                    Label(mode.title, systemImage: mode.iconName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(PrototypeTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: settingsViewModel.themeMode == mode
                                          ? "checkmark.circle.fill"
                                          : "circle")
                                        .foregroundStyle(settingsViewModel.themeMode == mode
                                                         ? PrototypeTheme.accent
                                                         : PrototypeTheme.textTertiary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if settingsViewModel.isLoading || settingsViewModel.isSaving || settingsViewModel.errorMessage != nil {
                    SettingsStatusView(
                        isLoading: settingsViewModel.isLoading && !settingsViewModel.hasLoaded,
                        isSaving: settingsViewModel.isSaving,
                        errorMessage: settingsViewModel.errorMessage
                    )
                }
            }
            .onAppear { settingsViewModel.loadIfNeeded() }
        }
    }
}
