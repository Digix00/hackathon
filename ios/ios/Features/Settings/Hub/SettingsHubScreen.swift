import SwiftUI

struct SettingsHubView: View {
    let restartOnboarding: () -> Void

    private var appSettings: [SettingsDestination] {
        [
            SettingsDestination(id: "share-track", icon: "music.note", title: "シェアする曲", destination: { AnyView(SearchView()) }),
            SettingsDestination(id: "encounter-settings", icon: "location.fill", title: "すれ違い設定", destination: { AnyView(EncounterSettingsView()) }),
            SettingsDestination(id: "notification-settings", icon: "bell.fill", title: "通知設定", destination: { AnyView(NotificationSettingsView()) }),
            SettingsDestination(id: "appearance-settings", icon: "paintbrush.fill", title: "外観", destination: { AnyView(AppearanceSettingsView()) })
        ]
    }

    private var privacySettings: [SettingsDestination] {
        [
            SettingsDestination(id: "block-mute", icon: "hand.raised.fill", title: "ブロック / ミュート", destination: { AnyView(BlockMuteListView()) }),
            SettingsDestination(id: "other-user-profile", icon: "person.wave.2.fill", title: "他ユーザープロフィール例", destination: { AnyView(OtherUserProfileStandaloneView()) })
        ]
    }

    private var linkedServices: [SettingsDestination] {
        [
            SettingsDestination(id: "music-services", icon: "music.quarternote.3", title: "音楽サービス連携", destination: { AnyView(MusicServicesView()) })
        ]
    }

    private var prototypeEntries: [SettingsDestination] {
        [
            SettingsDestination(id: "empty-states", icon: "rectangle.stack.fill", title: "空状態・エラー状態", destination: { AnyView(EmptyStatesGalleryView()) }),
            SettingsDestination(id: "realtime-demo", icon: "dot.radiowaves.left.and.right", title: "リアルタイム演出", destination: { AnyView(RealtimeDemoView()) }),
            SettingsDestination(id: "restart-onboarding", icon: "sparkles", title: "オンボーディングをやり直す", destination: { AnyView(RestartOnboardingView(restartOnboarding: restartOnboarding)) }),
            SettingsDestination(id: "delete-account", icon: "trash.fill", title: "アカウント削除", destination: { AnyView(DeleteAccountView()) })
        ]
    }

    var body: some View {
        AppScaffold(
            title: "Settings",
            subtitle: "PREFERENCES & SYSTEM"
        ) {
            VStack(alignment: .leading, spacing: 44) {
                // --- PROFILE SECTION ---
                VStack(spacing: 24) {
                    HStack(spacing: 20) {
                        // Elevated Avatar with Ring
                        ZStack {
                            Circle()
                                .fill(PrototypeTheme.surface)
                                .frame(width: 84, height: 84)
                                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.8))
                            
                            // Accent Ring (Minimal Decoration)
                            Circle()
                                .stroke(PrototypeTheme.accent.opacity(0.15), lineWidth: 1)
                                .frame(width: 94, height: 94)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("Miyu")
                                    .font(.system(size: 28, weight: .bold))
                                    .tracking(-0.8)
                                
                                Text("ID: 0x82A1")
                                    .prototypeFont(size: 8, weight: .black, role: .data)
                                    .foregroundStyle(PrototypeTheme.textTertiary)
                                    .kerning(1.2)
                            }
                            
                            Text("音楽で街の空気を集めたい")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)

                    NavigationLink {
                        ProfileEditView()
                    } label: {
                        HStack {
                            Text("EDIT PROFILE")
                                .prototypeFont(size: 10, weight: .black, role: .data)
                                .kerning(2.0)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(PrototypeTheme.accent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(PrototypeTheme.surface)
                                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                // --- SETTINGS GROUPS ---
                Group {
                    settingsSection(title: "APPLICATION", items: appSettings)
                    settingsSection(title: "PRIVACY", items: privacySettings)
                    settingsSection(title: "SERVICES", items: linkedServices)
                    settingsSection(title: "EXPERIMENTAL", items: prototypeEntries)
                }

                // --- FOOTER ---
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(PrototypeTheme.border)
                            .frame(height: 0.5)
                        
                        Text("SYSTEM STATUS: OPTIMAL")
                            .prototypeFont(size: 8.5, weight: .black, role: .data)
                            .kerning(1.5)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                        
                        Rectangle()
                            .fill(PrototypeTheme.border)
                            .frame(height: 0.5)
                    }
                    
                    VStack(spacing: 4) {
                        Text("VERSION 0.1.0-RC")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                        Text("© 2026 URBAN SERENDIPITY PROJECT")
                            .font(.system(size: 9, weight: .bold))
                            .kerning(0.5)
                    }
                    .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.8))
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 4) // Additional inner padding for breathing room
        }
    }

    private func settingsSection(title: String, items: [SettingsDestination]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Eyebrow Header
            Text(title)
                .prototypeFont(size: 10, weight: .black, role: .data)
                .kerning(2.5)
                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.5))
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    NavigationLink {
                        item.destination()
                    } label: {
                        VStack(spacing: 0) {
                            SettingRow(icon: item.icon, title: item.title)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                            
                            if index < items.count - 1 {
                                Divider()
                                    .background(PrototypeTheme.border.opacity(0.5))
                                    .padding(.horizontal, 20)
                            }
                        }
                        .background(PrototypeTheme.surface)
                    }
                    .buttonStyle(.plain)
                    
                    // Subtle hover/press effect is handled by ButtonStyle if needed, 
                    // but here we keep it clean.
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 10)
        }
    }
}
