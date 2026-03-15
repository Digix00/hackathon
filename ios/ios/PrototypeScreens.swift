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
        AppScaffold(
            title: stepTitle,
            subtitle: stepSubtitle
        ) {
            VStack(spacing: 32) {
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

                Spacer()

                HStack(spacing: 16) {
                    if step > 0 && step < 3 {
                        Button(action: {
                            withAnimation(.spring()) { step -= 1 }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .frame(width: 56, height: 56)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(Circle())
                        }
                    }

                    PrimaryButton(title: step == 3 ? "BEGIN JOURNEY" : "CONTINUE") {
                        if step == 3 {
                            onFinish()
                        } else {
                            withAnimation(.spring()) { step += 1 }
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }

    private var stepTitle: String {
        switch step {
        case 0: return "Hello World."
        case 1: return "Identity"
        case 2: return "Presence"
        default: return "Ready."
        }
    }

    private var stepSubtitle: String {
        switch step {
        case 0: return "A NEW WAY TO CONNECT"
        case 1: return "HOW OTHERS WILL SEE YOU"
        case 2: return "SETTING UP THE BEACON"
        default: return "EVERYTHING IS SET"
        }
    }

    private var progress: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index == step ? PrototypeTheme.textPrimary : PrototypeTheme.border)
                    .frame(width: index == step ? 32 : 12, height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var onboardingWelcome: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(PrototypeTheme.border, lineWidth: 1)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .stroke(PrototypeTheme.border.opacity(0.5), lineWidth: 1)
                    .frame(width: 260, height: 260)
                
                Image(systemName: "waveform")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(PrototypeTheme.accent)
            }
            .padding(.vertical, 20)

            VStack(alignment: .leading, spacing: 16) {
                Text("URBAN SERENDIPITY")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(PrototypeTheme.accent)
                    .kerning(2.0)

                Text("すれ違う、\n音楽で繋がる。")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .lineSpacing(4)

                Text("街を歩くだけで、誰かの「今の気分」と出会える。新しい音楽体験を始めましょう。")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 8)
        }
    }

    private var onboardingProfile: some View {
        VStack(spacing: 24) {
            SectionCard(title: "YOUR PROFILE") {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(PrototypeTheme.surfaceElevated)
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NICKNAME")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("miyu")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SHARING TRACK")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        
                        HStack(spacing: 14) {
                            MockArtworkView(color: .indigo, symbol: "music.note", size: 52)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("夜に駆ける")
                                    .font(.system(size: 16, weight: .bold))
                                Text("YOASOBI")
                                    .font(.system(size: 14))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                        .padding(12)
                        .background(PrototypeTheme.surfaceElevated.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            
            Text("この情報はすれ違った相手にのみ公開されます。")
                .font(.system(size: 13))
                .foregroundStyle(PrototypeTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private var onboardingPermissions: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                PermissionRow(
                    icon: "location.fill",
                    title: "Location Services",
                    description: "近くの人を見つけるために使用します。"
                )
                PermissionRow(
                    icon: "dot.radiowaves.left.and.right",
                    title: "Bluetooth",
                    description: "BLE信号で安全にすれ違いを検知します。"
                )
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "新しい出会いや曲の生成をお知らせします。"
                )
            }
            
            GlassmorphicCard {
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(PrototypeTheme.success)
                    Text("プライバシーは保護されており、正確な現在地が共有されることはありません。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }
            }
        }
    }

    private var onboardingFinish: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(PrototypeTheme.success.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(PrototypeTheme.success)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                Text("READY TO EXPLORE")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(PrototypeTheme.success)
                    .kerning(1.5)
                
                Text("準備が完了しました")
                    .font(.system(size: 28, weight: .black))
                
                Text("iPhoneを持って街に出かけましょう。\n誰かの音楽があなたを待っています。")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
        }
    }
}

struct HomeView: View {
    @State private var selectedPage = 0
    @GestureState private var verticalDragOffset: CGFloat = 0

    private enum Page: Int {
        case hero
        case insights
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Main Content
                Group {
                    if currentPage == .hero {
                        HomeHeroPage(
                            state: homeState,
                            selectedPage: $selectedPage
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        HomeInsightsPage(
                            state: homeState,
                            topSafeAreaInset: proxy.safeAreaInsets.top,
                            selectedPage: $selectedPage
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                if currentPage == .hero {
                    // Keep the page indicator on the hero screen only.
                    // The insights screen already shows the ScrollView indicator.
                    HStack {
                        Spacer()
                        ZStack(alignment: .top) {
                            Capsule()
                                .fill(PrototypeTheme.border.opacity(0.35))
                                .frame(width: 3, height: 100)

                            Capsule()
                                .fill(PrototypeTheme.accent)
                                .frame(width: 3, height: 40)
                                .offset(y: currentPage == .hero ? 0 : 60)
                        }
                        .padding(.trailing, 20)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .offset(y: verticalDragOffset * 0.18)
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .updating($verticalDragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        handleVerticalSwipe(translation: value.translation.height)
                    }
            )
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: selectedPage)
        }
        .background(PrototypeTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var currentPage: Page {
        Page(rawValue: selectedPage) ?? .hero
    }

    private var homeState: HomeScreenState {
        MockData.home
    }

    private func handleVerticalSwipe(translation: CGFloat) {
        let threshold: CGFloat = 80
        if translation < -threshold, currentPage == .hero {
            selectedPage = Page.insights.rawValue
        } else if translation > threshold, currentPage == .insights {
            selectedPage = Page.hero.rawValue
        }
    }
}

private struct DynamicBlurBackground: View {
    let baseColor: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            PrototypeTheme.background.ignoresSafeArea()

            // メインのBlob 1
            Circle()
                .fill(baseColor.opacity(0.35))
                .frame(width: 450, height: 450)
                .offset(x: animate ? 80 : -80, y: animate ? -150 : -50)
                .blur(radius: 90)

            // メインのBlob 2
            Circle()
                .fill(PrototypeTheme.accent.opacity(0.12))
                .frame(width: 380, height: 380)
                .offset(x: animate ? -100 : 100, y: animate ? 200 : 100)
                .blur(radius: 100)

            // アクセントのBlob 3
            Circle()
                .fill(baseColor.opacity(0.2))
                .frame(width: 320, height: 320)
                .offset(x: animate ? 40 : -40, y: animate ? 50 : -50)
                .blur(radius: 80)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

private struct HomeHeroPage: View {
    let state: HomeScreenState
    @Binding var selectedPage: Int
    @State private var isSignaling = false

    private var heroColor: Color {
        state.featuredTrack?.color ?? PrototypeTheme.surfaceElevated
    }

    var body: some View {
        ZStack {
            DynamicBlurBackground(baseColor: heroColor)

            VStack {
                // Top Status Area
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("35.6812° N, 139.7671° E")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                        Text("TOKYO / SHIBUYA")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.4))
                            .kerning(1.5)
                    }
                    Spacer()
                    
                    // Minimal Status Indicator with Animation
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(PrototypeTheme.accent)
                                .frame(width: 6, height: 6)

                            Circle()
                                .stroke(PrototypeTheme.accent.opacity(0.3), lineWidth: 2)
                                .frame(width: 6, height: 6)
                                .scaleEffect(isSignaling ? 2.5 : 1.0)
                                .opacity(isSignaling ? 0.0 : 0.8)
                        }
                        .onAppear {
                            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                                isSignaling = true
                            }
                        }

                        Text("BEACON ACTIVE")
                            .font(.system(size: 10, weight: .black))
                            .kerning(1.2)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(PrototypeTheme.surface.opacity(0.4))
                    .clipShape(Capsule())
                }
                .padding(.top, 24)

                Spacer()

                NavigationLink {
                    SearchView()
                } label: {
                    FeaturedTrackHeroCard(track: state.featuredTrack)
                }
                .buttonStyle(.plain)

                Spacer()

                // Bottom Hint
                VStack(spacing: 12) {
                    Text("SWIPE UP FOR INSIGHTS")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.5))
                        .kerning(2.0)
                    
                    Capsule()
                        .fill(PrototypeTheme.border.opacity(0.6))
                        .frame(width: 40, height: 4)
                }
                .padding(.bottom, 12)
            }
            .padding(32)
        }
    }
}

private struct HomeInsightsPage: View {
    let state: HomeScreenState
    let topSafeAreaInset: CGFloat
    @Binding var selectedPage: Int

    private var contentTopPadding: CGFloat {
        topSafeAreaInset + 12
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if state.isOffline {
                    OfflineBannerView()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("すれ違いの情報")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                }

                if !state.weeklyTracks.isEmpty {
                    SectionCard {
                        SectionHeader(title: "今週出会った音楽")

                        WeeklyMusicCollageView(tracks: state.weeklyTracks)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("すれ違い")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(PrototypeTheme.textPrimary)

                    HStack(spacing: 14) {
                        SummaryMetricCard(
                            title: "今日",
                            count: state.todayEncounterCount,
                            zeroMessage: "まだありません"
                        )
                        SummaryMetricCard(
                            title: "今週",
                            count: state.weekEncounterCount,
                            zeroMessage: "まだありません"
                        )
                    }
                }

                SectionCard {
                    SectionHeader(title: "最近の出会い", showsAction: !state.recentEncounters.isEmpty)

                    if state.recentEncounters.isEmpty {
                        FirstEncounterEmptyState()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(state.recentEncounters.prefix(5)) { encounter in
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
            .padding(.horizontal, 20)
            .padding(.top, contentTopPadding)
            .padding(.bottom, 28)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.height > 80 {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedPage = 0
                        }
                    }
                }
        )
        .background(PrototypeTheme.background)
    }
}

private struct SectionHeader: View {
    let title: String
    var showsAction = true

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(PrototypeTheme.textPrimary)
            Spacer()
            if showsAction {
                NavigationLink("すべて") {
                    EncounterListView()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(PrototypeTheme.accent)
            }
        }
    }
}

private struct FeaturedTrackHeroCard: View {
    let track: Track?
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 48) {
            if let track {
                VStack(spacing: 40) {
                    ZStack {
                        // Background Glow
                        Circle()
                            .fill(track.color.opacity(0.15))
                            .frame(width: 340, height: 340)
                            .scaleEffect(isPulsing ? 1.15 : 1.0)
                            .blur(radius: isPulsing ? 32 : 20)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isPulsing)

                        // Outer ring
                        Circle()
                            .stroke(track.color.opacity(0.1), lineWidth: 1)
                            .frame(width: 300, height: 300)
                            .scaleEffect(isPulsing ? 1.05 : 0.95)
                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isPulsing)

                        MockArtworkView(color: track.color, symbol: "music.note", size: 240)
                            .shadow(color: track.color.opacity(0.2), radius: 30, x: 0, y: 15)
                    }
                    .onAppear { isPulsing = true }

                    VStack(spacing: 12) {
                        Text("CURRENTLY SHARING")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(track.color.opacity(0.7))
                            .kerning(1.5)
                        
                        Text(track.title)
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .tracking(-1.0)

                        Text(track.artist)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 12)
                }
            } else {
                VStack(spacing: 32) {
                    Circle()
                        .fill(PrototypeTheme.surfaceMuted)
                        .frame(width: 140, height: 140)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }

                    Text("SET YOUR TRACK")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .kerning(1.2)
                }
            }
        }
        .frame(maxWidth: .infinity)
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
        AppScaffold(
            title: encounter.track.title,
            subtitle: "3 MINUTES AGO • SHIBUYA STATION",
            accentColor: encounter.track.color
        ) {
            VStack(alignment: .leading, spacing: 24) {
                // Main Track Info Card
                VStack(spacing: 24) {
                    MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 160)
                        .shadow(color: encounter.track.color.opacity(0.3), radius: 30, x: 0, y: 15)
                    
                    VStack(spacing: 8) {
                        Text(encounter.track.title)
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .tracking(-0.5)
                        
                        Text(encounter.track.artist)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                    
                    Button(action: { showsProfile = true }) {
                        HStack(spacing: 8) {
                            MockArtworkView(color: .gray, symbol: "person.fill", size: 24)
                            Text(encounter.userName)
                                .font(.system(size: 14, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .black))
                        }
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(PrototypeTheme.surface.opacity(0.6))
                        .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)

                // Lyric Fragment - Glassmorphic
                GlassmorphicCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(encounter.track.color)
                            Spacer()
                            Text("LYRIC FRAGMENT")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .kerning(1.2)
                        }
                        
                        Text(encounter.lyric)
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .italic()
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .lineSpacing(4)
                        
                        HStack {
                            Spacer()
                            Image(systemName: "quote.closing")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(encounter.track.color)
                        }
                    }
                }

                // Interaction Area
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "heart.fill")
                                Text("LIKE")
                            }
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(encounter.track.color)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .frame(width: 52, height: 52)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    
                    PrimaryButton(title: "ADD YOUR LYRIC", systemImage: "sparkles") {
                        showsLyricModal = true
                    }
                }

                // Extra Debug Section
                NavigationLink {
                    RealtimeDemoView()
                } label: {
                    HStack {
                        Text("VIEW ENCOUNTER LOG")
                            .font(.system(size: 12, weight: .black))
                            .kerning(1.0)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .black))
                    }
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .padding(16)
                    .background(PrototypeTheme.surfaceMuted.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .background(PrototypeTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 14))

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
                                .fill(PrototypeTheme.surfaceElevated)
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

private struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(PrototypeTheme.warning)
            Text("オフラインです")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PrototypeTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(PrototypeTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct FirstEncounterEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            EmptyStateCard(
                icon: "figure.walk",
                title: "まだすれ違いがありません",
                message: "新しい出会いを待っています",
                tint: PrototypeTheme.info
            )
        }
    }
}

private struct WeeklyMusicCollageView: View {
    let tracks: [Track]

    private var visibleTracks: [Track] { Array(tracks.prefix(7)) }

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(56), spacing: 8), count: 4)

        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(visibleTracks) { track in
                NavigationLink {
                    EncounterListView()
                } label: {
                    MockArtworkView(color: track.color, symbol: "music.note", size: 56)
                }
                .buttonStyle(.plain)
            }

            if tracks.count > visibleTracks.count {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(PrototypeTheme.surfaceElevated)
                        .frame(width: 56, height: 56)
                    Text("+\(tracks.count - visibleTracks.count)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }
            }
        }
    }
}

private struct SummaryMetricCard: View {
    let title: String
    let count: Int
    let zeroMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                Text("人")
                    .font(.system(size: 13))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            Text(count == 0 ? zeroMessage : " ")
                .font(.system(size: 12))
                .foregroundStyle(PrototypeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(PrototypeTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)のすれ違い、\(count)人")
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
        .background(PrototypeTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
