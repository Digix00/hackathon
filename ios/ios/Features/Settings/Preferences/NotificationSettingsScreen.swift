import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var settingsViewModel: UserSettingsViewModel

    var body: some View {
        AppScaffold(
            title: "通知設定",
            subtitle: "COMMS & ALERTS"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("ALERT PROTOCOLS")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Spacer()
                        Text("NTF-01")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                    }
                    .padding(.horizontal, 4)

                    GlassmorphicCard {
                        VStack(spacing: 0) {
                            toggleRow(
                                title: "すれ違い検知",
                                subtitle: "近くで誰かを見つけた時に通知",
                                code: "NTF-MATCH",
                                isOn: Binding(
                                    get: { settingsViewModel.encounterNotificationEnabled },
                                    set: { settingsViewModel.setEncounterNotifications($0) }
                                )
                            )

                            Divider()
                                .background(PrototypeTheme.border.opacity(0.5))
                                .padding(.vertical, 16)

                            toggleRow(
                                title: "まとめて通知",
                                subtitle: "複数の通知をまとめて受け取る",
                                code: "NTF-BATCH",
                                isOn: Binding(
                                    get: { settingsViewModel.batchNotificationEnabled },
                                    set: { settingsViewModel.setBatchNotifications($0) }
                                )
                            )
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

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(PrototypeTheme.accent)
                        Text("SYSTEM BROADCAST")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }

                    Text("通知をオフにしても、アプリ内の交換履歴はリアルタイムで更新されます。まとめて通知をオンにすると、複数の更新を整理して受け取れます。")
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

    private func toggleRow(title: String, subtitle: String, code: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))

                    Text(code)
                        .prototypeFont(size: 8, weight: .black, role: .data)
                        .foregroundStyle(PrototypeTheme.accent.opacity(0.5))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(PrototypeTheme.accent.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .tint(PrototypeTheme.accent)
                .labelsHidden()
        }
    }
}
