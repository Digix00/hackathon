import SwiftUI

struct SettingsHubView: View {
    let restartOnboarding: () -> Void
    @StateObject private var settingsViewModel = UserSettingsViewModel()

    private var appSettings: [SettingsDestination] {
        [
            SettingsDestination(id: "share-track", icon: "music.note", title: "シェアする曲", destination: AnyView(SearchView())),
            SettingsDestination(
                id: "encounter-settings",
                icon: "location.fill",
                title: "すれ違い設定",
                destination: AnyView(EncounterSettingsView().environmentObject(settingsViewModel))
            ),
            SettingsDestination(
                id: "notification-settings",
                icon: "bell.fill",
                title: "通知設定",
                destination: AnyView(NotificationSettingsView().environmentObject(settingsViewModel))
            ),
            SettingsDestination(
                id: "appearance-settings",
                icon: "paintbrush.fill",
                title: "外観",
                destination: AnyView(AppearanceSettingsView().environmentObject(settingsViewModel))
            )
        ]
    }

    private var privacySettings: [SettingsDestination] {
        [
            SettingsDestination(id: "block-mute", icon: "hand.raised.fill", title: "ブロック / ミュート", destination: AnyView(BlockMuteListView())),
            SettingsDestination(id: "other-user-profile", icon: "person.wave.2.fill", title: "他ユーザープロフィール例", destination: AnyView(OtherUserProfileStandaloneView()))
        ]
    }

    private var linkedServices: [SettingsDestination] {
        [
            SettingsDestination(id: "music-services", icon: "music.quarternote.3", title: "音楽サービス連携", destination: AnyView(MusicServicesView()))
        ]
    }

    private var prototypeEntries: [SettingsDestination] {
        [
            SettingsDestination(id: "empty-states", icon: "rectangle.stack.fill", title: "空状態・エラー状態", destination: AnyView(EmptyStatesGalleryView())),
            SettingsDestination(id: "realtime-demo", icon: "dot.radiowaves.left.and.right", title: "リアルタイム演出", destination: AnyView(RealtimeDemoView())),
            SettingsDestination(id: "restart-onboarding", icon: "sparkles", title: "オンボーディングをやり直す", destination: AnyView(RestartOnboardingView(restartOnboarding: restartOnboarding))),
            SettingsDestination(id: "delete-account", icon: "trash.fill", title: "アカウント削除", destination: AnyView(DeleteAccountView()))
        ]
    }

    var body: some View {
        AppScaffold(
            title: "設定",
            subtitle: "アプリの使い方を調整"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                // Profile Header
                SectionCard {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(PrototypeTheme.surfaceElevated)
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                        
                        VStack(spacing: 6) {
                            Text("Miyu")
                                .font(.system(size: 24, weight: .bold))
                            Text("音楽で街の空気を集めたい")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }
                        
                        NavigationLink {
                            ProfileEditView()
                        } label: {
                            Text("プロフィールを編集")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(PrototypeTheme.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                settingsGroup(title: "アプリ設定", items: appSettings)
                settingsGroup(title: "プライバシー", items: privacySettings)
                settingsGroup(title: "連携", items: linkedServices)
                settingsGroup(title: "プロトタイプ", items: prototypeEntries)
                
                VStack(spacing: 8) {
                    Text("VERSION 0.1.0")
                        .prototypeFont(size: 10, weight: .bold, role: .data)
                    Text("© 2026 すれ違い趣味交換")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(PrototypeTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .onAppear { settingsViewModel.loadIfNeeded() }
    }

    private func settingsGroup(title: String, items: [SettingsDestination]) -> some View {
        SectionCard(title: title) {
            VStack(spacing: 18) {
                ForEach(items) { item in
                    NavigationLink {
                        item.destination
                    } label: {
                        SettingRow(icon: item.icon, title: item.title)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
