import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var settingsViewModel: UserSettingsViewModel

    var body: some View {
        AppScaffold(
            title: "通知設定",
            subtitle: "受け取る通知を管理"
        ) {
            VStack(spacing: 24) {
                SectionCard {
                    VStack(spacing: 20) {
                        Toggle(isOn: Binding(
                            get: { settingsViewModel.encounterNotificationEnabled },
                            set: { settingsViewModel.setEncounterNotifications($0) }
                        )) {
                            Text("すれ違い通知")
                                .font(.system(size: 16, weight: .bold))
                        }

                        Toggle(isOn: Binding(
                            get: { settingsViewModel.generatedNotificationEnabled },
                            set: { settingsViewModel.setGeneratedNotifications($0) }
                        )) {
                            Text("生成曲の通知")
                                .font(.system(size: 16, weight: .bold))
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
