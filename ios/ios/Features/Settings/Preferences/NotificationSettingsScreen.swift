import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var settingsViewModel: UserSettingsViewModel
    @EnvironmentObject private var pushManager: PushNotificationManager

    var body: some View {
        AppScaffold(
            title: "通知設定",
            subtitle: "COMMS & ALERTS",
            showsBackButton: true
        ) {
            VStack(alignment: .leading, spacing: 56) {
                
                // --- Section: ALERT PROTOCOLS ---
                VStack(alignment: .leading, spacing: 32) {
                    settingLabel("ALERT PROTOCOLS")

                    VStack(spacing: 0) {
                        toggleRow(
                            title: "プッシュ通知",
                            subtitle: "システムからの重要な通知を受け取ります",
                            isOn: Binding(
                                get: { settingsViewModel.notificationEnabled },
                                set: { settingsViewModel.setNotificationEnabled($0) }
                            )
                        )

                        separator()

                        toggleRow(
                            title: "すれ違い検知",
                            subtitle: "近くで誰かを見つけた時にリアルタイムで通知",
                            isOn: Binding(
                                get: { settingsViewModel.encounterNotificationEnabled },
                                set: { settingsViewModel.setEncounterNotifications($0) }
                            )
                        )

                        separator()

                        toggleRow(
                            title: "まとめて通知",
                            subtitle: "複数の通知を整理して配信",
                            isOn: Binding(
                                get: { settingsViewModel.batchNotificationEnabled },
                                set: { settingsViewModel.setBatchNotifications($0) }
                            )
                        )
                    }
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(PrototypeTheme.surface.opacity(0.4))
                            .shadow(color: Color.black.opacity(0.02), radius: 15, x: 0, y: 8)
                    )

                    if let warning = notificationWarningMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                            Text(warning)
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(PrototypeTheme.error)
                        .padding(.horizontal, 16)
                    }
                }

                // --- Status indicator ---
                if settingsViewModel.isLoading || settingsViewModel.isSaving || settingsViewModel.errorMessage != nil {
                    SettingsStatusView(
                        isLoading: settingsViewModel.isLoading && !settingsViewModel.hasLoaded,
                        isSaving: settingsViewModel.isSaving,
                        errorMessage: settingsViewModel.errorMessage
                    )
                    .padding(.horizontal, 8)
                }

                // --- Footer / System Info ---
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(PrototypeTheme.accent.opacity(0.5))
                        Text("SYSTEM BROADCAST")
                            .prototypeFont(size: 10, weight: .black, role: .data)
                            .kerning(2.5)
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                    }

                    Text("通知をオフにしても、アプリ内の交換履歴はリアルタイムで更新されます。まとめて通知をオンにすると、複数の更新を整理して受け取れます。")
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

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 20)
        }
        .padding(.horizontal, 28)
        .tint(PrototypeTheme.accent)
    }

    private func separator() -> some View {
        Divider()
            .background(PrototypeTheme.border.opacity(0.4))
            .padding(.horizontal, 28)
    }

    private func settingLabel(_ text: String) -> some View {
        Text(text)
            .prototypeFont(size: 11, weight: .black, role: .data)
            .kerning(2.5)
            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
            .padding(.leading, 8)
    }

    private var notificationWarningMessage: String? {
        guard settingsViewModel.notificationEnabled else { return nil }
        if pushManager.authorizationStatus == .denied {
            return "通知が許可されていません。設定アプリから通知を許可してください。"
        }
        if let message = pushManager.lastErrorMessage {
            return message
        }
        return nil
    }
}
