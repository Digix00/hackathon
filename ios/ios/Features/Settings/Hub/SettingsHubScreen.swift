import SwiftUI

struct SettingsHubView: View {
    let restartOnboarding: () -> Void
    @StateObject private var settingsViewModel = UserSettingsViewModel()
    @StateObject private var profileViewModel = CurrentUserProfileViewModel()
    @State private var isBeating = false
    @State private var signOutErrorMessage: String?
    @EnvironmentObject private var authSession: AuthSession

    private var appSettings: [SettingsDestination] {
        [
            SettingsDestination(id: "share-track", icon: "music.note", title: "シェアする曲", destination: { lockedDestination(SearchView()) }),
            SettingsDestination(
                id: "encounter-settings",
                icon: "location.fill",
                title: "すれ違い設定",
                destination: { lockedDestination(EncounterSettingsView().environmentObject(settingsViewModel)) }
            ),
            SettingsDestination(
                id: "notification-settings",
                icon: "bell.fill",
                title: "通知設定",
                destination: { lockedDestination(NotificationSettingsView().environmentObject(settingsViewModel)) }
            )
        ]
    }

    private var privacySettings: [SettingsDestination] {
        [
            SettingsDestination(id: "block-mute", icon: "hand.raised.fill", title: "ブロック / ミュート", destination: { lockedDestination(BlockMuteListView()) }),
            SettingsDestination(id: "other-user-profile", icon: "person.wave.2.fill", title: "他ユーザープロフィール例", destination: { lockedDestination(OtherUserProfileStandaloneView()) })
        ]
    }

    private var linkedServices: [SettingsDestination] {
        [
            SettingsDestination(id: "music-services", icon: "music.quarternote.3", title: "音楽サービス連携", destination: { lockedDestination(MusicServicesView()) })
        ]
    }

    private var prototypeEntries: [SettingsDestination] {
        [
            SettingsDestination(id: "empty-states", icon: "rectangle.stack.fill", title: "空状態・エラー状態", destination: { lockedDestination(EmptyStatesGalleryView()) }),
            SettingsDestination(id: "realtime-demo", icon: "dot.radiowaves.left.and.right", title: "リアルタイム演出", destination: { lockedDestination(RealtimeDemoView()) }),
            SettingsDestination(id: "generated-song-previews", icon: "music.note.tv.fill", title: "生成曲プレビュー画面", destination: { lockedDestination(GeneratedSongPreviewGalleryView()) }),
            SettingsDestination(id: "restart-onboarding", icon: "sparkles", title: "オンボーディングをやり直す", destination: { lockedDestination(RestartOnboardingView(restartOnboarding: restartOnboarding)) }),
            SettingsDestination(
                id: "delete-account",
                icon: "trash.fill",
                title: "アカウント削除",
                destination: { lockedDestination(DeleteAccountView(onAccountDeleted: restartOnboarding)) }
            )
        ]
    }

    var body: some View {
        AppScaffold(
            title: "Settings",
            subtitle: "PREFERENCES & SYSTEM"
        ) {
            VStack(alignment: .leading, spacing: 56) {
                // Compact Horizontal Profile Header
                NavigationLink {
                    ProfileEditView()
                } label: {
                    HStack(spacing: 20) {
                        UserAvatarView(
                            avatarURL: profileViewModel.user?.avatarURL,
                            size: 72, // Compact but clear
                            iconSize: 32
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
                        .overlay(
                            Circle()
                                .stroke(PrototypeTheme.border.opacity(0.1), lineWidth: 1)
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(profileViewModel.user?.displayName ?? "読み込み中...")
                                .font(.system(size: 22, weight: .black))
                                .tracking(-0.5)
                                .foregroundStyle(PrototypeTheme.textPrimary)

                            let bio = profileViewModel.user?.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            Text(bio.isEmpty ? "ひとこと未設定" : bio)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.4))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(PrototypeTheme.surface.opacity(0.4))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 8)

                VStack(spacing: 48) {
                    settingsSection(title: "ACCOUNT", items: appSettings)
                    settingsSection(title: "PRIVACY", items: privacySettings)
                    settingsSection(title: "SERVICES", items: linkedServices)
                    settingsSection(title: "DEVELOPER", items: prototypeEntries)
                    settingsActionSection(
                        title: "SESSION",
                        message: signOutErrorMessage,
                        isDestructive: true,
                        isDisabled: authSession.isSigningOut,
                        icon: "rectangle.portrait.and.arrow.right",
                        titleText: authSession.isSigningOut ? "ログアウト中..." : "ログアウト",
                        action: handleSignOut
                    )
                }

                // Simplified Footer
                VStack(spacing: 24) {
                    Divider()
                        .background(PrototypeTheme.border.opacity(0.3))

                    VStack(spacing: 8) {
                        Text("URBAN SERENDIPITY")
                            .prototypeFont(size: 10, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        
                        Text("v0.1.0-RELEASE")
                            .prototypeFont(size: 9, weight: .medium, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            settingsViewModel.loadIfNeeded()
            profileViewModel.refresh()
        }
    }

    private func handleSignOut() {
        signOutErrorMessage = nil

        do {
            try authSession.signOut()
        } catch {
            signOutErrorMessage = error.localizedDescription
        }
    }

    private func lockedDestination<Content: View>(_ view: Content) -> AnyView {
        AnyView(
            view
                .lockLibraryPageSwipe()
                .disableInteractivePopGesture(true)
        )
    }

    private func settingsSection(title: String, items: [SettingsDestination]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .prototypeFont(size: 11, weight: .black, role: .data)
                .kerning(1.8)
                .foregroundStyle(PrototypeTheme.textSecondary)
                .padding(.horizontal, 8)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    NavigationLink {
                        item.destination()
                    } label: {
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .frame(width: 24)
                                
                                Text(item.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.5))
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 24)

                            if index < items.count - 1 {
                                Divider()
                                    .background(PrototypeTheme.border.opacity(0.3))
                                    .padding(.leading, 64) // Offset divider
                                    .padding(.trailing, 24)
                            }
                        }
                        .background(PrototypeTheme.surface.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(PrototypeTheme.border.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func settingsActionSection(
        title: String,
        message: String?,
        isDestructive: Bool = false,
        isDisabled: Bool = false,
        icon: String,
        titleText: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .prototypeFont(size: 11, weight: .black, role: .data)
                .kerning(1.8)
                .foregroundStyle(PrototypeTheme.textSecondary)
                .padding(.horizontal, 8)

            VStack(spacing: 12) {
                if let message {
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                }

                Button(action: action) {
                    HStack(spacing: 16) {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(isDestructive ? PrototypeTheme.error : PrototypeTheme.textSecondary)
                            .frame(width: 24)

                        Text(titleText)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isDestructive ? PrototypeTheme.error : PrototypeTheme.textPrimary)

                        Spacer()
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 24)
                    .background(PrototypeTheme.surface.opacity(0.5))
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
                .opacity(isDisabled ? 0.6 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        isDestructive ? PrototypeTheme.error.opacity(0.18) : PrototypeTheme.border.opacity(0.3),
                        lineWidth: 1
                    )
            )
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
