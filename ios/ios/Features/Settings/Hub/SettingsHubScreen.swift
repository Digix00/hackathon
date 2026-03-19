import SwiftUI

struct SettingsHubView: View {
    let restartOnboarding: () -> Void
    @StateObject private var settingsViewModel = UserSettingsViewModel()
    @StateObject private var profileViewModel = CurrentUserProfileViewModel()
    @State private var isBeating = false

    private var appSettings: [SettingsDestination] {
        [
            SettingsDestination(id: "share-track", icon: "music.note", title: "シェアする曲", destination: { AnyView(SearchView()) }),
            SettingsDestination(
                id: "encounter-settings",
                icon: "location.fill",
                title: "すれ違い設定",
                destination: { AnyView(EncounterSettingsView().environmentObject(settingsViewModel)) }
            ),
            SettingsDestination(
                id: "notification-settings",
                icon: "bell.fill",
                title: "通知設定",
                destination: { AnyView(NotificationSettingsView().environmentObject(settingsViewModel)) }
            ),
            SettingsDestination(
                id: "appearance-settings",
                icon: "paintbrush.fill",
                title: "外観",
                destination: { AnyView(AppearanceSettingsView().environmentObject(settingsViewModel)) }
            )
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
            SettingsDestination(
                id: "delete-account",
                icon: "trash.fill",
                title: "アカウント削除",
                destination: { AnyView(DeleteAccountView(onAccountDeleted: restartOnboarding)) }
            )
        ]
    }

    var body: some View {
        AppScaffold(
            title: "Settings",
            subtitle: "PREFERENCES & SYSTEM"
        ) {
            VStack(alignment: .leading, spacing: 44) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(PrototypeTheme.success)
                            .frame(width: 8, height: 8)
                            .opacity(isBeating ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isBeating)

                        Text("BEACON ACTIVE")
                            .prototypeFont(size: 10, weight: .black, role: .data)
                            .kerning(1.5)
                            .foregroundStyle(PrototypeTheme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(PrototypeTheme.success.opacity(0.1))
                    .clipShape(Capsule())

                    Spacer()

                    Text("35.6586° N, 139.7454° E")
                        .prototypeFont(size: 10, weight: .medium, role: .data)
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }
                .padding(.top, -10)
                .onAppear { isBeating = true }

                GlassmorphicCard {
                    VStack(spacing: 24) {
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .stroke(PrototypeTheme.accent.opacity(0.2), lineWidth: 2)
                                    .frame(width: 84, height: 84)
                                    .scaleEffect(isBeating ? 1.2 : 1.0)
                                    .opacity(isBeating ? 0.0 : 0.5)
                                    .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: false), value: isBeating)

                                UserAvatarView(
                                    avatarURL: profileViewModel.user?.avatarURL,
                                    size: 84,
                                    iconSize: 38
                                )
                                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)

                                Circle()
                                    .fill(PrototypeTheme.success)
                                    .frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .offset(x: 28, y: 28)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(profileViewModel.user?.displayName ?? "読み込み中...")
                                    .font(.system(size: 28, weight: .bold))
                                    .tracking(-1.0)

                                let bio = profileViewModel.user?.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                                Text(bio.isEmpty ? "ひとこと未設定" : bio)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)

                                if let errorMessage = profileViewModel.errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(PrototypeTheme.error)
                                        .padding(.top, 4)
                                }
                            }

                            Spacer()
                        }

                        NavigationLink {
                            ProfileEditView()
                        } label: {
                            HStack {
                                Text("MODIFY PROTOCOL")
                                    .prototypeFont(size: 10, weight: .black, role: .data)
                                    .kerning(2.0)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(PrototypeTheme.accent)
                                    .shadow(color: PrototypeTheme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }

                VStack(spacing: 32) {
                    settingsSection(title: "CORE CONFIGURATION", code: "SYS-01", items: appSettings)
                    settingsSection(title: "PRIVACY PROTOCOLS", code: "PRV-02", items: privacySettings)
                    settingsSection(title: "SERVICE INTEGRATION", code: "SRV-03", items: linkedServices)
                    settingsSection(title: "EXPERIMENTAL MODULES", code: "EXP-04", items: prototypeEntries)
                }

                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(PrototypeTheme.border)
                            .frame(height: 1)

                        Text("DIAGNOSTIC SUMMARY")
                            .prototypeFont(size: 10, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textTertiary)

                        Rectangle()
                            .fill(PrototypeTheme.border)
                            .frame(height: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("STATUS:")
                                .prototypeFont(size: 9, weight: .black, role: .data)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("ALL SYSTEMS OPTIMAL")
                                .prototypeFont(size: 9, weight: .medium, role: .data)
                                .foregroundStyle(PrototypeTheme.success)
                            Spacer()
                            Text("uptime: 14:22:01")
                                .prototypeFont(size: 9, weight: .medium, role: .data)
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }

                        HStack {
                            Text("KERNEL:")
                                .prototypeFont(size: 9, weight: .black, role: .data)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("SERENDIPITY-OS v0.1.0-RELEASE")
                                .prototypeFont(size: 9, weight: .medium, role: .data)
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }

                        HStack {
                            Text("LOCALITY:")
                                .prototypeFont(size: 9, weight: .black, role: .data)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("TOKYO-DISTRICT-03")
                                .prototypeFont(size: 9, weight: .medium, role: .data)
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                    }
                    .padding(16)
                    .background(PrototypeTheme.surfaceMuted.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("© 2026 URBAN SERENDIPITY PROJECT · NO RIGHTS RESERVED")
                        .prototypeFont(size: 8, weight: .black, role: .data)
                        .kerning(1.0)
                        .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                        .padding(.top, 10)
                }
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            settingsViewModel.loadIfNeeded()
            profileViewModel.refresh()
        }
    }

    private func settingsSection(title: String, code: String, items: [SettingsDestination]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .prototypeFont(size: 11, weight: .black, role: .data)
                    .kerning(2.0)
                    .foregroundStyle(PrototypeTheme.textSecondary)

                Spacer()

                Text(code)
                    .prototypeFont(size: 9, weight: .black, role: .data)
                    .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    NavigationLink {
                        item.destination()
                    } label: {
                        VStack(spacing: 0) {
                            SettingRow(icon: item.icon, title: item.title)
                                .padding(.vertical, 18)
                                .padding(.horizontal, 20)

                            if index < items.count - 1 {
                                Divider()
                                    .background(PrototypeTheme.border.opacity(0.5))
                                    .padding(.horizontal, 20)
                            }
                        }
                        .background(PrototypeTheme.surface.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(PrototypeTheme.border.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 8)
        }
    }
}

private struct UserAvatarView: View {
    let avatarURL: String?
    let size: CGFloat
    let iconSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(PrototypeTheme.surfaceElevated)
                .frame(width: size, height: size)

            if let avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.fill")
                        .font(.system(size: iconSize))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(PrototypeTheme.textTertiary)
            }
        }
    }
}
