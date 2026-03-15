import SwiftUI

struct MainPrototypeView: View {
    enum Tab {
        case home
        case encounters
        case favorites
        case profile
    }

    @State private var selectedTab: Tab = .home
    let restartOnboarding: () -> Void

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }
            .tag(Tab.home)

            NavigationStack {
                EncounterListView()
            }
            .tabItem {
                Label("履歴", systemImage: "list.bullet")
            }
            .tag(Tab.encounters)

            NavigationStack {
                GeneratedSongsView()
            }
            .tabItem {
                Label("生成曲", systemImage: "heart.text.square.fill")
            }
            .tag(Tab.favorites)

            NavigationStack {
                SettingsHubView(restartOnboarding: restartOnboarding)
            }
            .tabItem {
                Label("プロフィール", systemImage: "person.circle.fill")
            }
            .tag(Tab.profile)
        }
        .tint(PrototypeTheme.accent)
    }
}

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [PrototypeTheme.background, PrototypeTheme.surfaceMuted],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(PrototypeTheme.surface)
                        .frame(width: 104, height: 104)
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                }
                .overlay(
                    Circle()
                        .stroke(PrototypeTheme.border, lineWidth: 1)
                )

                Text("すれ違い趣味交換")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                Text("街を歩くだけで、誰かの音楽と出会える")
                    .font(.system(size: 15))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            .padding(24)
        }
    }
}

struct OnboardingFlowView: View {
    @State private var step = 0
    let onFinish: () -> Void

    var body: some View {
        AppScaffold(title: step == 0 ? "ようこそ" : "はじめる準備") {
            VStack(spacing: 18) {
                progress

                Group {
                    switch step {
                    case 0:
                        onboardingWelcome
                    case 1:
                        onboardingProfile
                    case 2:
                        onboardingPermissions
                    default:
                        onboardingFinish
                    }
                }

                HStack(spacing: 12) {
                    if step > 0 {
                        SecondaryButton(title: "戻る") {
                            step -= 1
                        }
                    }

                    PrimaryButton(title: step == 3 ? "はじめる" : "次へ") {
                        if step == 3 {
                            onFinish()
                        } else {
                            step += 1
                        }
                    }
                }
            }
        }
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? PrototypeTheme.accent : PrototypeTheme.border)
                    .frame(height: 6)
            }
        }
    }

    private var onboardingWelcome: some View {
        VStack(spacing: 16) {
            SectionCard {
                VStack(alignment: .leading, spacing: 18) {
                    Text("すれ違いから始まる\n新しい音楽体験")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                    Text("街を歩くだけで、誰かのお気に入りの曲と出会えるアプリです。")
                        .font(.system(size: 16))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                    SecondaryButton(title: "Apple で続ける", systemImage: "apple.logo") {}
                    SecondaryButton(title: "Google で続ける", systemImage: "globe") {}
                }
            }
        }
    }

    private var onboardingProfile: some View {
        VStack(spacing: 16) {
            SectionCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("あなたのことを教えてください")
                        .font(.system(size: 24, weight: .bold))
                    HStack(spacing: 16) {
                        MockArtworkView(color: .gray, symbol: "person.fill", size: 72)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ニックネーム")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("miyu")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    Divider()
                    Text("今日シェアしたい曲")
                        .font(.system(size: 20, weight: .semibold))
                    TrackSelectionRow(track: MockData.featuredTrack)
                }
            }
        }
    }

    private var onboardingPermissions: some View {
        VStack(spacing: 16) {
            SectionCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("近くの人と出会うための許可")
                        .font(.system(size: 24, weight: .bold))
                    PermissionRow(icon: "location.fill", title: "位置情報", description: "近くの人を見つけるために使います。")
                    PermissionRow(icon: "dot.radiowaves.left.and.right", title: "Bluetooth", description: "すれ違いを検知するために使います。")
                    PermissionRow(icon: "bell.fill", title: "通知", description: "新しい出会いや生成曲をお知らせします。")
                }
            }
        }
    }

    private var onboardingFinish: some View {
        VStack(spacing: 16) {
            SectionCard {
                VStack(spacing: 18) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(PrototypeTheme.success)
                    Text("準備ができました")
                        .font(.system(size: 24, weight: .bold))
                    Text("街を歩くと、近くにいる人の音楽と出会えます。")
                        .font(.system(size: 15))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct HomeView: View {
    @State private var showsLyricModal = false

    var body: some View {
        AppScaffold(title: "こんにちは、Miyuさん", trailingSymbol: "bell.badge") {
            VStack(alignment: .leading, spacing: 20) {
                SectionCard(title: "今日シェアしている曲") {
                    VStack(spacing: 14) {
                        MockArtworkView(color: MockData.featuredTrack.color, symbol: "music.note", size: 128)
                        Text(MockData.featuredTrack.title)
                            .font(.system(size: 24, weight: .bold))
                        Text(MockData.featuredTrack.artist)
                            .font(.system(size: 16))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        NavigationLink {
                            SearchView()
                        } label: {
                            Text("変更")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(PrototypeTheme.accent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                NavigationLink {
                    ChainProgressView()
                } label: {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("あなたの歌詞が曲になる途中")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                            HStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { index in
                                    Circle()
                                        .fill(index == 2 ? PrototypeTheme.textPrimary : PrototypeTheme.textTertiary)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            Text("3/4 人参加中  「今日も空は青かった」")
                                .font(.system(size: 14))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                SectionCard {
                    HStack {
                        Text("今週出会った音楽")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        NavigationLink("すべて") {
                            EncounterListView()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PrototypeTheme.accent)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(MockData.tracks.prefix(7)) { track in
                            MockArtworkView(color: track.color, symbol: "music.note", size: 60)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("すれ違い")
                        .font(.system(size: 18, weight: .semibold))
                    HStack(spacing: 12) {
                        StatCard(title: "今日", value: "12", footnote: "街を歩いて出会いが増えています")
                        StatCard(title: "今週", value: "47", footnote: "今週の合計")
                    }
                }

                SectionCard {
                    HStack {
                        Text("最近の出会い")
                            .font(.system(size: 18, weight: .semibold))
                        Spacer()
                        Button("歌詞を残す") {
                            showsLyricModal = true
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PrototypeTheme.accent)
                    }

                    ForEach(MockData.encounters.prefix(3)) { encounter in
                        NavigationLink {
                            EncounterDetailView(encounter: encounter)
                        } label: {
                            EncounterRow(encounter: encounter)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showsLyricModal) {
            LyricInputModalView()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    NotificationsPlaceholderView()
                } label: {
                    Image(systemName: "bell")
                        .foregroundStyle(PrototypeTheme.textPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsHubView(restartOnboarding: {})
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(PrototypeTheme.textPrimary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EncounterListView: View {
    var body: some View {
        AppScaffold(title: "すれ違い履歴", trailingSymbol: "magnifyingglass") {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(["今日", "昨日"], id: \.self) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(section)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(PrototypeTheme.textSecondary)

                        ForEach(MockData.encounters.filter { section == "今日" ? $0.relativeTime != "昨日" : $0.relativeTime == "昨日" }) { encounter in
                            NavigationLink {
                                EncounterDetailView(encounter: encounter)
                            } label: {
                                EncounterRow(encounter: encounter)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct EncounterDetailView: View {
    let encounter: Encounter
    @State private var showsProfile = false
    @State private var showsLyricModal = false

    var body: some View {
        AppScaffold(title: encounter.track.title) {
            VStack(alignment: .leading, spacing: 18) {
                SectionCard {
                    HStack(spacing: 16) {
                        MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 72)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(encounter.track.title)
                                .font(.system(size: 22, weight: .bold))
                            Text(encounter.track.artist)
                                .font(.system(size: 15))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Button(encounter.userName) {
                                showsProfile = true
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(PrototypeTheme.accent)
                        }
                        Spacer()
                    }
                }

                SectionCard(title: "この出会いのことば") {
                    Text(encounter.lyric)
                        .font(.system(size: 20, weight: .semibold))
                    Text("3分前のすれ違いで記録された歌詞メモ")
                        .font(.system(size: 14))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: "いいね", systemImage: "heart") {}
                    SecondaryButton(title: "通報", systemImage: "flag") {}
                }

                PrimaryButton(title: "歌詞を残す", systemImage: "sparkles") {
                    showsLyricModal = true
                }

                NavigationLink {
                    RealtimeDemoView()
                } label: {
                    SectionCard {
                        Text("リアルタイム演出のたたき台を見る")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showsProfile) {
            OtherUserProfileView()
        }
        .sheet(isPresented: $showsLyricModal) {
            LyricInputModalView()
        }
    }
}

struct SearchView: View {
    @State private var query = "夜に駆ける"

    var body: some View {
        AppScaffold(title: "曲を検索") {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text(query)
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }
                .padding(14)
                .background(PrototypeTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(PrototypeTheme.border, lineWidth: 1)
                )

                SectionCard(title: "最近検索した曲") {
                    ForEach(MockData.recentSearches) { track in
                        TrackSelectionRow(track: track)
                    }
                }

                SectionCard(title: "人気の曲") {
                    ForEach(MockData.popularTracks) { track in
                        TrackSelectionRow(track: track)
                    }
                }

                SectionCard(title: "選択中の曲") {
                    VStack(alignment: .leading, spacing: 12) {
                        TrackSelectionRow(track: MockData.featuredTrack)
                        PrimaryButton(title: "決定") {}
                    }
                }
            }
        }
    }
}

struct GeneratedSongsView: View {
    var body: some View {
        AppScaffold(title: "生成曲") {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(MockData.generatedSongs) { song in
                    NavigationLink {
                        GeneratedSongDetailView(song: song)
                    } label: {
                        SectionCard {
                            HStack(spacing: 16) {
                                MockArtworkView(color: song.color, symbol: "waveform", size: 56)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(song.title)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(PrototypeTheme.textPrimary)
                                    Text(song.subtitle)
                                        .font(.system(size: 13))
                                        .foregroundStyle(PrototypeTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(PrototypeTheme.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    GeneratedSongNotificationView()
                } label: {
                    SectionCard {
                        Text("生成完了通知の演出を見る")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)

                NavigationLink {
                    GeneratingStateView()
                } label: {
                    SectionCard {
                        Text("生成中・失敗状態を見る")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct GeneratedSongDetailView: View {
    let song: GeneratedSong

    var body: some View {
        AppScaffold(title: song.title) {
            VStack(alignment: .leading, spacing: 18) {
                SectionCard {
                    VStack(spacing: 16) {
                        MockArtworkView(color: song.color, symbol: "waveform.and.magnifyingglass", size: 140)
                        Text(song.title)
                            .font(.system(size: 26, weight: .bold))
                        Text(song.subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        PrimaryButton(title: "再生する", systemImage: "play.fill") {}
                    }
                    .frame(maxWidth: .infinity)
                }

                SectionCard(title: "参加した歌詞") {
                    ForEach(Array(MockData.encounters.prefix(4).enumerated()), id: \.offset) { index, encounter in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(index + 1). \(encounter.lyric)")
                                .font(.system(size: 15, weight: .medium))
                            Text(encounter.userName)
                                .font(.system(size: 12))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }
}

struct GeneratedSongNotificationView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .blue], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Text("曲が生まれました")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                Text("「夜明けの詩」")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                PrimaryButton(title: "聴いてみる", systemImage: "play.fill") {}
                Button("あとで聴く") {}
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(24)
        }
    }
}

struct GeneratingStateView: View {
    var body: some View {
        AppScaffold(title: "生成状態") {
            VStack(spacing: 18) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("生成中", systemImage: "waveform.circle")
                            .font(.system(size: 20, weight: .semibold))
                        ProgressView(value: 0.65)
                            .tint(PrototypeTheme.accent)
                        Text("4人の歌詞をまとめて曲にしています。")
                            .font(.system(size: 14))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                }

                SectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("エラー状態", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(PrototypeTheme.error)
                        Text("生成に失敗しました。ネットワークの再接続後に再試行してください。")
                            .font(.system(size: 14))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        SecondaryButton(title: "再試行") {}
                    }
                }
            }
        }
    }
}

struct ChainProgressView: View {
    var body: some View {
        AppScaffold(title: "歌詞チェーン") {
            VStack(alignment: .leading, spacing: 18) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Circle().fill(PrototypeTheme.textTertiary).frame(width: 12, height: 12)
                            Circle().fill(PrototypeTheme.textPrimary).frame(width: 12, height: 12)
                            Circle().fill(PrototypeTheme.accent).frame(width: 12, height: 12)
                            Circle().fill(PrototypeTheme.textTertiary).frame(width: 12, height: 12)
                        }
                        Text("3/4 人参加中")
                            .font(.system(size: 22, weight: .bold))
                        Text("あと 1 人で曲が生まれます")
                            .font(.system(size: 14))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                }

                SectionCard(title: "参加者の歌詞") {
                    ForEach(Array(MockData.encounters.prefix(3).enumerated()), id: \.offset) { index, encounter in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(index + 1). \(encounter.lyric)")
                                .font(.system(size: 15, weight: .medium))
                            Text(encounter.userName)
                                .font(.system(size: 12))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }
                    }
                    Text("4. 誰かを待っています...")
                        .font(.system(size: 15))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .padding(.top, 4)
                }
            }
        }
    }
}

struct LyricInputModalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var lyric = "今日も空は青かった"

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                }

                Text("この出会いに一言")
                    .font(.system(size: 24, weight: .bold))
                TextEditor(text: $lyric)
                    .frame(height: 140)
                    .padding(10)
                    .background(PrototypeTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text("\(lyric.count)/100")
                    .font(.system(size: 13))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("この歌詞は他のすれ違いと組み合わさり、AI が曲を作ります。")
                    .font(.system(size: 14))
                    .foregroundStyle(PrototypeTheme.textSecondary)

                PrimaryButton(title: "歌詞を残す", isDisabled: lyric.isEmpty) {
                    dismiss()
                }
                Button("スキップ") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(PrototypeTheme.accent)

                Spacer()
            }
            .padding(20)
            .background(PrototypeTheme.background)
        }
        .presentationDetents([.medium, .large])
    }
}

struct NotificationsPlaceholderView: View {
    var body: some View {
        AppScaffold(title: "通知") {
            EmptyStateCard(
                icon: "bell.badge",
                title: "通知はまだありません",
                message: "すれ違いや生成曲が発生するとここにまとまって表示されます。",
                tint: PrototypeTheme.info
            )
        }
    }
}

struct OtherUserProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Capsule()
                    .fill(PrototypeTheme.border)
                    .frame(width: 52, height: 5)
                    .padding(.top, 8)

                MockArtworkView(color: .gray, symbol: "person.fill", size: 84)
                Text("Airi")
                    .font(.system(size: 24, weight: .bold))
                Text("夜の散歩とシティポップが好き")
                    .font(.system(size: 15))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .multilineTextAlignment(.center)

                SectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("好きな曲", systemImage: "music.note")
                        TrackSelectionRow(track: MockData.tracks[1])
                    }
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: "ミュート", systemImage: "speaker.slash") {}
                    SecondaryButton(title: "通報", systemImage: "flag") {}
                }

                Spacer()
            }
            .padding(20)
            .background(PrototypeTheme.background)
        }
        .presentationDetents([.medium, .large])
    }
}

struct SettingsHubView: View {
    let restartOnboarding: () -> Void

    var body: some View {
        AppScaffold(title: "設定") {
            VStack(alignment: .leading, spacing: 18) {
                SectionCard {
                    VStack(spacing: 12) {
                        MockArtworkView(color: .gray, symbol: "person.fill", size: 80)
                        Text("Miyu")
                            .font(.system(size: 22, weight: .bold))
                        Text("音楽で街の空気を集めたい")
                            .font(.system(size: 14))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        NavigationLink {
                            ProfileEditView()
                        } label: {
                            Text("プロフィールを編集")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(PrototypeTheme.accent)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                settingsGroup(title: "アプリ設定", items: [
                    ("music.note", "シェアする曲", AnyView(SearchView())),
                    ("location.fill", "すれ違い設定", AnyView(EncounterSettingsView())),
                    ("bell.fill", "通知設定", AnyView(NotificationSettingsView())),
                    ("paintbrush.fill", "外観", AnyView(AppearanceSettingsView()))
                ])

                settingsGroup(title: "プライバシー", items: [
                    ("hand.raised.fill", "ブロック / ミュート", AnyView(BlockMuteListView())),
                    ("person.wave.2.fill", "他ユーザープロフィール例", AnyView(OtherUserProfileStandaloneView()))
                ])

                settingsGroup(title: "連携", items: [
                    ("music.quarternote.3", "音楽サービス連携", AnyView(MusicServicesView()))
                ])

                settingsGroup(title: "プロトタイプ一覧", items: [
                    ("rectangle.stack.fill", "空状態・エラー状態", AnyView(EmptyStatesGalleryView())),
                    ("dot.radiowaves.left.and.right", "リアルタイム演出", AnyView(RealtimeDemoView())),
                    ("sparkles", "オンボーディングをやり直す", AnyView(RestartOnboardingView(restartOnboarding: restartOnboarding))),
                    ("trash.fill", "アカウント削除", AnyView(DeleteAccountView()))
                ])
            }
        }
    }

    private func settingsGroup(title: String, items: [(String, String, AnyView)]) -> some View {
        SectionCard(title: title) {
            VStack(spacing: 14) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    NavigationLink {
                        item.2
                    } label: {
                        SettingRow(icon: item.0, title: item.1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ProfileEditView: View {
    var body: some View {
        AppScaffold(title: "プロフィール編集") {
            VStack(alignment: .leading, spacing: 18) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ニックネーム")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Text("Miyu")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(PrototypeTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Text("ひとこと")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Text("音楽で街の空気を集めたい")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(PrototypeTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                PrimaryButton(title: "保存") {}
            }
        }
    }
}

struct EncounterSettingsView: View {
    var body: some View {
        AppScaffold(title: "すれ違い設定") {
            VStack(spacing: 18) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("検知半径")
                            .font(.system(size: 18, weight: .semibold))
                        Text("現在: 30m")
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Slider(value: .constant(0.6))
                            .tint(PrototypeTheme.accent)
                    }
                }
                SectionCard {
                    Toggle(isOn: .constant(true)) {
                        Text("公開範囲を広めにする")
                    }
                }
            }
        }
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        AppScaffold(title: "通知設定") {
            SectionCard {
                VStack(spacing: 16) {
                    Toggle(isOn: .constant(true)) {
                        Text("すれ違い通知")
                    }
                    Toggle(isOn: .constant(true)) {
                        Text("生成曲通知")
                    }
                    Toggle(isOn: .constant(false)) {
                        Text("まとめ通知")
                    }
                }
            }
        }
    }
}

struct BlockMuteListView: View {
    var body: some View {
        AppScaffold(title: "ブロック / ミュート") {
            VStack(spacing: 18) {
                SectionCard(title: "ブロック") {
                    SettingRow(icon: "hand.raised.fill", title: "ren_music")
                }
                SectionCard(title: "ミュート") {
                    SettingRow(icon: "speaker.slash.fill", title: "midnight_city")
                }
            }
        }
    }
}

struct MusicServicesView: View {
    var body: some View {
        AppScaffold(title: "音楽サービス連携") {
            VStack(spacing: 18) {
                SectionCard {
                    SettingRow(icon: "music.note.list", title: "Spotify", subtitle: "接続済み")
                    SettingRow(icon: "music.note.house", title: "Apple Music", subtitle: "未接続")
                }
            }
        }
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        AppScaffold(title: "外観") {
            SectionCard {
                VStack(spacing: 12) {
                    Label("ライトモード優先のモノトーン", systemImage: "sun.max.fill")
                    Label("アルバムカラーを差し色に使用", systemImage: "paintpalette.fill")
                    Label("後続でダークモード精密化", systemImage: "moon.fill")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct DeleteAccountView: View {
    var body: some View {
        AppScaffold(title: "アカウント削除") {
            VStack(spacing: 18) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("この操作は元に戻せません。")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(PrototypeTheme.error)
                        Text("保存済みのプロフィール、履歴、参加した歌詞チェーンへの導線が削除されます。")
                            .font(.system(size: 14))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                }
                SecondaryButton(title: "削除フローを見る") {}
            }
        }
    }
}

struct RestartOnboardingView: View {
    let restartOnboarding: () -> Void

    var body: some View {
        AppScaffold(title: "オンボーディング再表示") {
            VStack(spacing: 18) {
                EmptyStateCard(
                    icon: "sparkles",
                    title: "オンボーディングをやり直します",
                    message: "たたき台確認用に、いつでも最初の導線に戻れます。",
                    tint: PrototypeTheme.info
                )
                PrimaryButton(title: "再表示する") {
                    restartOnboarding()
                }
            }
        }
    }
}

struct OtherUserProfileStandaloneView: View {
    var body: some View {
        AppScaffold(title: "他ユーザープロフィール") {
            OtherUserProfileCard()
        }
    }
}

struct EmptyStatesGalleryView: View {
    @State private var scenario: EmptyScenario = .firstEncounter

    var body: some View {
        AppScaffold(title: "空状態・エラー状態") {
            VStack(alignment: .leading, spacing: 18) {
                Picker("状態", selection: $scenario) {
                    ForEach(EmptyScenario.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                switch scenario {
                case .firstEncounter:
                    EmptyStateCard(
                        icon: "figure.walk",
                        title: "まだすれ違いがありません",
                        message: "通勤・通学の時間帯や、人が多い場所で試すと出会いやすくなります。",
                        tint: PrototypeTheme.info
                    )
                case .inactive:
                    EmptyStateCard(
                        icon: "music.note.house",
                        title: "最近すれ違いが少ないようです",
                        message: "検知範囲を 30m から 50m に広げるたたき台を用意しています。",
                        tint: PrototypeTheme.warning
                    )
                case .searchEmpty:
                    EmptyStateCard(
                        icon: "magnifyingglass",
                        title: "検索結果がありません",
                        message: "スペル確認か別キーワードで再検索する導線を後続で付けます。",
                        tint: PrototypeTheme.textSecondary
                    )
                case .network:
                    EmptyStateCard(
                        icon: "wifi.exclamationmark",
                        title: "通信エラー",
                        message: "接続を確認して再試行してください。オフライン時はキャッシュ表示へ寄せます。",
                        tint: PrototypeTheme.error
                    )
                case .bluetooth:
                    EmptyStateCard(
                        icon: "dot.radiowaves.left.and.right.slash",
                        title: "Bluetooth を許可してください",
                        message: "近くの人を検知するには Bluetooth 権限が必要です。",
                        tint: PrototypeTheme.info
                    )
                }
            }
        }
    }
}

struct RealtimeDemoView: View {
    @State private var scenario: RealtimeScenario = .standby

    var body: some View {
        AppScaffold(title: "リアルタイム演出") {
            VStack(alignment: .leading, spacing: 18) {
                Picker("状態", selection: $scenario) {
                    ForEach(RealtimeScenario.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                SectionCard {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .stroke(PrototypeTheme.border, lineWidth: 2)
                                .frame(width: 160, height: 160)
                            Circle()
                                .fill(circleColor.opacity(0.18))
                                .frame(width: circleSize, height: circleSize)
                            MockArtworkView(color: circleColor, symbol: "music.note", size: 80)
                        }
                        Text(statusTitle)
                            .font(.system(size: 22, weight: .bold))
                        Text(statusMessage)
                            .font(.system(size: 14))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var circleColor: Color {
        switch scenario {
        case .standby:
            return .gray
        case .approaching:
            return .yellow
        case .matched:
            return .green
        case .afterglow:
            return .indigo
        }
    }

    private var circleSize: CGFloat {
        switch scenario {
        case .standby:
            return 120
        case .approaching:
            return 136
        case .matched:
            return 156
        case .afterglow:
            return 132
        }
    }

    private var statusTitle: String {
        switch scenario {
        case .standby:
            return "すれ違いを探しています"
        case .approaching:
            return "近くに誰かがいます"
        case .matched:
            return "新しいすれ違いが成立"
        case .afterglow:
            return "余韻を残して次の出会いへ"
        }
    }

    private var statusMessage: String {
        switch scenario {
        case .standby:
            return "ホーム画面のパルスリング相当の演出をここで確認できます。"
        case .approaching:
            return "BLE 信号を検知した直後の予兆状態です。"
        case .matched:
            return "ジャケット付きトーストと歌詞導線を後続で追加します。"
        case .afterglow:
            return "すれ違い成立後の落ち着いた余韻をモノトーンで見せます。"
        }
    }
}

private struct TrackSelectionRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 14) {
            MockArtworkView(color: track.color, symbol: "music.note", size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                Text(track.artist)
                    .font(.system(size: 13))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            Spacer()
        }
    }
}

private struct EncounterRow: View {
    let encounter: Encounter

    var body: some View {
        HStack(spacing: 14) {
            MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(encounter.track.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                Text(encounter.track.artist)
                    .font(.system(size: 13))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(encounter.userName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                Text(encounter.relativeTime)
                    .font(.system(size: 12))
                    .foregroundStyle(PrototypeTheme.textTertiary)
            }
        }
        .padding(14)
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(PrototypeTheme.border, lineWidth: 1)
        )
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(PrototypeTheme.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(PrototypeTheme.success)
        }
        .padding(12)
        .background(PrototypeTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct OtherUserProfileCard: View {
    var body: some View {
        SectionCard {
            VStack(spacing: 14) {
                MockArtworkView(color: .gray, symbol: "person.fill", size: 84)
                Text("Airi")
                    .font(.system(size: 22, weight: .bold))
                Text("夜の散歩とシティポップが好き")
                    .font(.system(size: 14))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    SecondaryButton(title: "ミュート") {}
                    SecondaryButton(title: "通報") {}
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
