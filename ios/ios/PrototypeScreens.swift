import SwiftUI
import UIKit
import Combine

private struct SettingsDestination: Identifiable {
    let id: String
    let icon: String
    let title: String
    let destination: AnyView
}

private struct EncounterLyricsList: View {
    let encounters: [Encounter]
    var waitingLine: String? = nil

    var body: some View {
        ForEach(Array(encounters.enumerated()), id: \.offset) { index, encounter in
            VStack(alignment: .leading, spacing: 4) {
                Text("\(index + 1). \(encounter.lyric)")
                    .font(.system(size: 15, weight: .medium))
                Text(encounter.userName)
                    .font(.system(size: 12))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
        }

        if let waitingLine {
            Text(waitingLine)
                .font(.system(size: 15))
                .foregroundStyle(PrototypeTheme.textTertiary)
                .padding(.top, 4)
        }
    }
}

// Environment key for matched-geometry namespace
private struct HeroNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID = Namespace().wrappedValue
}

extension EnvironmentValues {
    var heroNamespace: Namespace.ID {
        get { self[HeroNamespaceKey.self] }
        set { self[HeroNamespaceKey.self] = newValue }
    }
}

private enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

struct MainPrototypeView: View {
    private enum Surface {
        case track
        case library
    }

    enum LibraryTab: Int, CaseIterable {
        case insights
        case history
        case songs
        case profile

        var title: String {
            switch self {
            case .insights: return "すれ違い情報"
            case .history: return "履歴"
            case .songs: return "生成曲"
            case .profile: return "プロフィール"
            }
        }

        var symbol: String {
            switch self {
            case .insights: return "dot.radiowaves.left.and.right"
            case .history: return "clock.arrow.circlepath"
            case .songs: return "waveform"
            case .profile: return "person.crop.circle"
            }
        }
    }

    @State private var selectedSurface: Surface = .track
    @State private var selectedLibraryTab: LibraryTab = .insights
    @GestureState private var verticalDragOffset: CGFloat = 0
    let restartOnboarding: () -> Void
    @Namespace private var heroNamespace

    var body: some View {
        GeometryReader { proxy in
            let topSafeArea = proxy.safeAreaInsets.top
            let bottomSafeArea = proxy.safeAreaInsets.bottom
            let screenHeight = proxy.size.height

            ZStack {
                trackSurface
                    .environment(\.topSafeAreaInset, 0)
                    .environment(\.bottomSafeAreaInset, 0)
                    .offset(y: isShowingTrackSurface ? dragOffset : -screenHeight + dragOffset)
                    .opacity(isShowingTrackSurface ? 1.0 : 0.5)
                    .scaleEffect(isShowingTrackSurface ? 1.0 : 0.95)

                librarySurface
                    .environment(\.topSafeAreaInset, topSafeArea)
                    .environment(\.bottomSafeAreaInset, bottomSafeArea)
                    .offset(y: isShowingTrackSurface ? screenHeight + dragOffset : dragOffset)
                    .opacity(isShowingTrackSurface ? 0.5 : 1.0)
            }
            .contentShape(Rectangle())
            .clipped()
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .updating($verticalDragOffset) { value, state, _ in
                        guard isVerticalSwipe(value.translation) else { return }
                        state = value.translation.height
                    }
                    .onEnded { value in
                        guard isVerticalSwipe(value.translation) else { return }
                        handleVerticalSwipe(translation: value.translation.height)
                    }
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedSurface)
            .environment(\.heroNamespace, heroNamespace)
        }
        .background(PrototypeTheme.background)
        .ignoresSafeArea()
        .tint(PrototypeTheme.accent)
    }

    private var homeState: HomeScreenState {
        MockData.home
    }

    private var isShowingTrackSurface: Bool {
        selectedSurface == .track
    }

    private var trackSurface: some View {
        navigationContainer {
            HomeHeroPage(
                state: homeState,
                isMotionActive: isShowingTrackSurface
            )
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private var librarySurface: some View {
        TabView(selection: $selectedLibraryTab) {
            navigationContainer {
                HomeInsightsPage(
                    state: homeState
                )
            }
            .tag(LibraryTab.insights)

            navigationContainer {
                EncounterListView()
            }
            .tag(LibraryTab.history)

            navigationContainer {
                GeneratedSongsView()
            }
            .tag(LibraryTab.songs)

            navigationContainer {
                SettingsHubView(restartOnboarding: restartOnboarding)
            }
            .tag(LibraryTab.profile)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.clear)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    guard isVerticalSwipe(value.translation) else { return }
                    handleVerticalSwipe(translation: value.translation.height)
                }
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if selectedSurface == .library {
                LibraryFooter(
                    selectedTab: $selectedLibraryTab,
                    tabs: LibraryTab.allCases
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var dragOffset: CGFloat {
        switch selectedSurface {
        case .track:
            return min(0, verticalDragOffset * 0.9)
        case .library:
            return max(0, verticalDragOffset * 0.9)
        }
    }

    @ViewBuilder
    private func navigationContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            content()
        }
        .background(Color.clear)
    }

    private func isVerticalSwipe(_ translation: CGSize) -> Bool {
        abs(translation.height) > abs(translation.width)
    }

    private func handleVerticalSwipe(translation: CGFloat) {
        let threshold: CGFloat = 90
        if translation < -threshold, selectedSurface == .track {
            Haptics.impact(.medium)
            selectedSurface = .library
        } else if translation > threshold, selectedSurface == .library {
            Haptics.impact(.medium)
            selectedSurface = .track
        }
    }
}

private struct LibraryFooter: View {
    @Binding var selectedTab: MainPrototypeView.LibraryTab
    @Environment(\.bottomSafeAreaInset) private var bottomSafeArea
    let tabs: [MainPrototypeView.LibraryTab]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.rawValue) { tab in
                Button {
                    Haptics.impact(.light)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 24, weight: .medium))
                            .symbolRenderingMode(.hierarchical)

                        Text(tab.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selectedTab == tab ? PrototypeTheme.textPrimary : PrototypeTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(.thinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(PrototypeTheme.border.opacity(0.5))
                .frame(height: 0.5)
        }
        .padding(.bottom, bottomSafeArea)
        .frame(maxWidth: .infinity)
        .frame(height: 64 + bottomSafeArea, alignment: .top)
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
    private enum Step: Int, CaseIterable {
        case welcome
        case profile
        case permissions
        case finish

        var title: String {
            switch self {
            case .welcome: return "はじめよう"
            case .profile: return "プロフィール"
            case .permissions: return "権限設定"
            case .finish: return "準備完了"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome: return "A NEW WAY TO CONNECT"
            case .profile: return "HOW OTHERS WILL SEE YOU"
            case .permissions: return "SETTING UP THE BEACON"
            case .finish: return "EVERYTHING IS SET"
            }
        }

        var contentIndex: Int {
            rawValue
        }

        var isLast: Bool {
            self == .finish
        }
    }

    @State private var step: Step = .welcome
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
                    case .welcome:
                        onboardingWelcome
                    case .profile:
                        onboardingProfile
                    case .permissions:
                        onboardingPermissions
                    default:
                        onboardingFinish
                    }
                }

                Spacer()

                HStack(spacing: 16) {
                    if showsBackButton {
                        Button(action: {
                            moveToPreviousStep()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .frame(width: 56, height: 56)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(Circle())
                        }
                    }

                    PrimaryButton(title: primaryButtonTitle) {
                        if isLastStep {
                            onFinish()
                        } else {
                            moveToNextStep()
                        }
                    }
                }
            }
        }
    }

    private var stepTitle: String {
        step.title
    }

    private var stepSubtitle: String {
        step.subtitle
    }

    private var showsBackButton: Bool {
        step.rawValue > 0 && !isLastStep
    }

    private var isLastStep: Bool {
        step.isLast
    }

    private var primaryButtonTitle: String {
        isLastStep ? "はじめる" : "次へ"
    }

    private var progress: some View {
        HStack(spacing: 10) {
            ForEach(Step.allCases, id: \.rawValue) { currentStep in
                Capsule()
                    .fill(currentStep == step ? PrototypeTheme.textPrimary : PrototypeTheme.border)
                    .frame(width: currentStep == step ? 32 : 12, height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moveToPreviousStep() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(.spring()) {
            step = previous
        }
    }

    private func moveToNextStep() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation(.spring()) {
            step = next
        }
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
                    .font(PrototypeTheme.Typography.Onboarding.eyebrow)
                    .foregroundStyle(PrototypeTheme.accent)
                    .kerning(2.0)

                Text("すれ違う、\n音楽で繋がる。")
                    .font(PrototypeTheme.Typography.Onboarding.title)
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .lineSpacing(4)

                Text("街を歩くだけで、誰かの「今の気分」と出会える。新しい音楽体験を始めましょう。")
                    .font(PrototypeTheme.Typography.Onboarding.body)
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 8)
        }
    }

    private var onboardingProfile: some View {
        VStack(spacing: 24) {
            SectionCard(title: "プロフィール") {
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
                            Text("ニックネーム")
                                .font(PrototypeTheme.Typography.Onboarding.cardLabel)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("miyu")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("シェアする曲")
                            .font(PrototypeTheme.Typography.Onboarding.cardLabel)
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
                    .font(PrototypeTheme.Typography.Onboarding.eyebrow)
                    .foregroundStyle(PrototypeTheme.success)
                    .kerning(1.5)
                
                Text("準備が完了しました")
                    .font(PrototypeTheme.Typography.Onboarding.stepTitle)
                
                Text("iPhoneを持って街に出かけましょう。\n誰かの音楽があなたを待っています。")
                    .font(PrototypeTheme.Typography.Onboarding.body)
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
        }
    }
}

struct EncounterListView: View {
    private let sections = EncounterSection.allCases

    var body: some View {
        AppScaffold(
            title: "すれ違い",
            subtitle: "出会った音楽と相手の記録",
            trailingSymbol: "slider.horizontal.3"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(section.rawValue)
                                .font(PrototypeTheme.Typography.Encounter.eyebrow)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        
                            Spacer()
                            
                            Rectangle()
                                .fill(PrototypeTheme.border.opacity(0.5))
                                .frame(height: 1)
                        }

                        VStack(spacing: 12) {
                            ForEach(MockData.encounters(in: section)) { encounter in
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
}

struct EncounterDetailView: View {
    let encounter: Encounter
    @State private var showsProfile = false
    @State private var showsLyricModal = false

    var body: some View {
        AppScaffold(
            title: encounter.track.title,
            subtitle: "3分前・渋谷駅",
            accentColor: encounter.track.color
        ) {
            VStack(alignment: .leading, spacing: 24) {
                // Main Track Info Card
                VStack(spacing: 24) {
                    MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 160)
                        .shadow(color: encounter.track.color.opacity(0.3), radius: 30, x: 0, y: 15)
                    
                    VStack(spacing: 8) {
                        Text(encounter.track.title)
                            .font(PrototypeTheme.Typography.Encounter.screenTitle)
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .tracking(-0.5)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .truncationMode(.tail)
                        
                        Text(encounter.track.artist)
                            .font(PrototypeTheme.Typography.Encounter.sectionTitle)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: { showsProfile = true }) {
                        HStack(spacing: 8) {
                            MockArtworkView(color: .gray, symbol: "person.fill", size: 24)
                            Text(encounter.userName)
                                .font(PrototypeTheme.Typography.Encounter.action)
                            Image(systemName: "chevron.right")
                                .font(PrototypeTheme.Typography.Encounter.metaCompact)
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
                                .font(PrototypeTheme.Typography.Encounter.action)
                                .foregroundStyle(encounter.track.color)
                            Spacer()
                            Text("歌詞の断片")
                                .font(PrototypeTheme.Typography.Encounter.eyebrow)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .kerning(1.2)
                        }
                        
                        Text(encounter.lyric)
                            .prototypeFont(size: 22, weight: .bold, role: .accent)
                            .italic()
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .lineSpacing(4)
                        
                        HStack {
                            Spacer()
                            Image(systemName: "quote.closing")
                                .font(PrototypeTheme.Typography.Encounter.action)
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
                                Text("いいね")
                            }
                            .font(PrototypeTheme.Typography.Encounter.action)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(encounter.track.color)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "ellipsis")
                                .font(PrototypeTheme.Typography.Encounter.sectionTitle)
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .frame(width: 52, height: 52)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    
                    PrimaryButton(title: "歌詞を残す", systemImage: "sparkles") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showsLyricModal = true
                    }
                }

                // Extra Debug Section
                NavigationLink {
                    RealtimeDemoView()
                } label: {
                    HStack {
                        Text("リアルタイム演出を見る")
                            .font(PrototypeTheme.Typography.Encounter.metaCompact)
                            .kerning(1.0)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(PrototypeTheme.Typography.Encounter.metaCompact)
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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.heroNamespace) var heroNamespace
    @State private var query = "夜に駆ける"

    var body: some View {
        AppScaffold(
            title: "曲を検索",
            subtitle: "シェアする曲を選ぶ"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("曲画面に戻る")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(PrototypeTheme.surface.opacity(0.92))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                    
                    Text(query)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "mic.fill")
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(PrototypeTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)

                SectionCard(title: "最近検索した曲") {
                    VStack(spacing: 16) {
                        ForEach(MockData.recentSearches) { track in
                            TrackSelectionRow(track: track)
                        }
                    }
                }

                SectionCard(title: "人気の曲") {
                    VStack(spacing: 16) {
                        ForEach(MockData.popularTracks) { track in
                            TrackSelectionRow(track: track)
                        }
                    }
                }

                SectionCard(title: "選択中の曲") {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 16) {
                            MockArtworkView(color: MockData.featuredTrack.color, symbol: "music.note", size: 52)
                                .shadow(color: MockData.featuredTrack.color.opacity(0.15), radius: 8, x: 0, y: 4)
                                .matchedGeometryEffect(id: "hero_artwork_\(MockData.featuredTrack.id)", in: heroNamespace)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(MockData.featuredTrack.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .matchedGeometryEffect(id: "hero_title_\(MockData.featuredTrack.id)", in: heroNamespace)
                                Text(MockData.featuredTrack.artist)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .matchedGeometryEffect(id: "hero_artist_\(MockData.featuredTrack.id)", in: heroNamespace)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(PrototypeTheme.success)
                        }
                        PrimaryButton(title: "この曲をシェアする") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let fromLeadingEdge = value.startLocation.x < 32
                    let isBackSwipe = value.translation.width > 90 && abs(value.translation.height) < 80
                    if fromLeadingEdge && isBackSwipe {
                        dismiss()
                    }
                }
        )
    }
}

struct GeneratedSongsView: View {
    var body: some View {
        AppScaffold(
            title: "生成曲",
            subtitle: "すれ違いから生まれた曲",
            trailingSymbol: "plus.app"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(MockData.generatedSongs) { song in
                    NavigationLink {
                        GeneratedSongDetailView(song: song)
                    } label: {
                        HStack(spacing: 18) {
                            MockArtworkView(color: song.color, symbol: "waveform", size: 64)
                                .shadow(color: song.color.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(song.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Text(song.subtitle)
                                    .prototypeFont(size: 13, weight: .medium, role: .data)
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(song.color)
                        }
                        .padding(16)
                        .background(PrototypeTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 16) {
                    NavigationLink {
                        GeneratedSongNotificationView()
                    } label: {
                        SecondaryButtonLabel(title: "生成完了通知を見る", systemImage: "bell.badge")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        GeneratingStateView()
                    } label: {
                        SecondaryButtonLabel(title: "生成状態を見る", systemImage: "sparkles.rectangle.stack")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
    }
}

struct GeneratedSongDetailView: View {
    let song: GeneratedSong
    private let contributingEncounters = MockData.generatedSongContributors

    var body: some View {
        AppScaffold(
            title: song.title,
            subtitle: "4件のすれ違いから生成",
            accentColor: song.color
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard {
                    VStack(spacing: 24) {
                        MockArtworkView(color: song.color, symbol: "waveform.and.magnifyingglass", size: 180)
                            .shadow(color: song.color.opacity(0.3), radius: 40, x: 0, y: 20)
                        
                        VStack(spacing: 8) {
                            Text(song.title)
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .truncationMode(.tail)
                            
                            Text(song.subtitle)
                                .prototypeFont(size: 15, weight: .bold, role: .data)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity)
                        
                        PrimaryButton(title: "再生する", systemImage: "play.fill") {}
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                SectionCard(title: "参加した歌詞") {
                    VStack(alignment: .leading, spacing: 20) {
                        EncounterLyricsList(encounters: contributingEncounters)
                    }
                }
                
                HStack(spacing: 12) {
                    SecondaryButton(title: "共有", systemImage: "square.and.arrow.up") {}
                    SecondaryButton(title: "保存", systemImage: "folder.badge.plus") {}
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct GeneratedSongNotificationView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            DynamicBackground(baseColor: .indigo)
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .blur(radius: 30)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    MockArtworkView(color: .indigo, symbol: "sparkles", size: 120)
                        .shadow(color: .indigo.opacity(0.8), radius: isAnimating ? 40 : 20, x: 0, y: 15)
                        .rotationEffect(.degrees(isAnimating ? 8 : -8))
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
                }
                .onAppear {
                    isAnimating = true
                }
                
                VStack(spacing: 16) {
                    Text("新しい曲が生まれました")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white.opacity(0.7))
                        .kerning(2.0)
                    
                    Text("「夜明けの詩」")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(.white)
                    
                    Text("渋谷でのすれ違いから生まれた曲です。")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    PrimaryButton(title: "今すぐ聴く", systemImage: "play.fill") {}
                    Button("あとで") {}
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(32)
        }
    }
}

struct GeneratingStateView: View {
    var body: some View {
        AppScaffold(
            title: "生成状態",
            subtitle: "AI作曲の進行状況"
        ) {
            VStack(spacing: 24) {
                SectionCard(title: "生成中") {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Label("歌詞を編集中", systemImage: "waveform.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Text("65%")
                                .prototypeFont(size: 14, weight: .black, role: .data)
                        }
                        .foregroundStyle(PrototypeTheme.accent)
                        
                        ProgressView(value: 0.65)
                            .tint(PrototypeTheme.accent)
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                        
                        Text("4人の歌詞をまとめて1曲にしています。")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .lineSpacing(4)
                    }
                }

                SectionCard(title: "エラー") {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("接続が中断されました", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(PrototypeTheme.error)
                        
                        Text("AIサーバーへの接続に失敗しました。")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        
                        SecondaryButton(title: "再試行", systemImage: "arrow.clockwise") {}
                    }
                }
            }
        }
    }
}

struct ChainProgressView: View {
    private let contributingEncounters = MockData.chainContributors

    var body: some View {
        AppScaffold(
            title: "歌詞チェーン",
            subtitle: "歌詞を集めています"
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(index < 3 ? PrototypeTheme.accent : PrototypeTheme.border)
                                    .frame(width: 14, height: 14)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("3/4人が参加")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            
                            Text("あと1人で曲が完成します。")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                        }
                    }
                }

                SectionCard(title: "集まった歌詞") {
                    VStack(alignment: .leading, spacing: 20) {
                        EncounterLyricsList(
                            encounters: contributingEncounters,
                            waitingLine: "4. 最後のひとりを待っています..."
                        )
                    }
                }
            }
        }
    }
}

struct LyricInputModalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var lyric = "今日も空は青かった"
    @State private var didTriggerNearLimitHaptic = false

    var body: some View {
        NavigationStack {
            ZStack {
                PrototypeTheme.background.ignoresSafeArea()
                
                // Subtle blur background accent
                Circle()
                    .fill(PrototypeTheme.accent.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 100, y: -200)

                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("この出会いを残す")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(PrototypeTheme.accent)
                            .kerning(2.0)
                        
                        Text("この出会いに一言")
                            .font(.system(size: 32, weight: .black))
                    }
                    
                    VStack(spacing: 12) {
                        TextEditor(text: $lyric)
                            .scrollContentBackground(.hidden)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(PrototypeTheme.surface.opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .frame(height: 160)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                            .onChange(of: lyric) { newValue in
                                let isNearLimit = newValue.count >= 90
                                if isNearLimit && !didTriggerNearLimitHaptic {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    didTriggerNearLimitHaptic = true
                                } else if !isNearLimit {
                                    didTriggerNearLimitHaptic = false
                                }
                            }
                        
                        HStack {
                            Spacer()
                            Text("\(lyric.count)/100")
                                .prototypeFont(size: 12, weight: .bold, role: .data)
                                .foregroundStyle(lyric.count > 90 ? PrototypeTheme.error : PrototypeTheme.textTertiary)
                        }
                    }

                    Text("この言葉はAI生成曲の一部になります。")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)

                    VStack(spacing: 16) {
                        PrimaryButton(title: "歌詞を送信", systemImage: "paperplane.fill", isDisabled: lyric.isEmpty) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                        }
                        
                        Button("今はスキップ") {
                            dismiss()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                    }

                    Spacer()
                }
                .padding(28)
            }
        }
        .presentationDetents([.large])
    }
}

struct NotificationsPlaceholderView: View {
    var body: some View {
        AppScaffold(
            title: "通知",
            subtitle: "最新の更新"
        ) {
            EmptyStateCard(
                icon: "bell.badge.fill",
                title: "まだ通知はありません",
                message: "すれ違いや生成曲があると、ここに表示されます。",
                tint: PrototypeTheme.accent
            )
        }
    }
}

struct OtherUserProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Capsule()
                    .fill(PrototypeTheme.border)
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(PrototypeTheme.surfaceElevated)
                            .frame(width: 100, height: 100)
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(PrototypeTheme.textTertiary)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Airi")
                            .font(.system(size: 28, weight: .black))
                        
                        Text("夜の散歩とシティポップが好き")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                SectionCard(title: "いまシェアしている曲") {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("現在のシェア曲", systemImage: "music.note")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(PrototypeTheme.accent)
                        
                        TrackSelectionRow(track: MockData.previewSharedTrack)
                    }
                }

                HStack(spacing: 16) {
                    SecondaryButton(title: "ミュート", systemImage: "speaker.slash.fill") {}
                    SecondaryButton(title: "通報", systemImage: "flag.fill") {}
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .background(PrototypeTheme.background)
        }
        .presentationDetents([.medium, .large])
    }
}

struct SettingsHubView: View {
    let restartOnboarding: () -> Void

    private var appSettings: [SettingsDestination] {
        [
            SettingsDestination(id: "share-track", icon: "music.note", title: "シェアする曲", destination: AnyView(SearchView())),
            SettingsDestination(id: "encounter-settings", icon: "location.fill", title: "すれ違い設定", destination: AnyView(EncounterSettingsView())),
            SettingsDestination(id: "notification-settings", icon: "bell.fill", title: "通知設定", destination: AnyView(NotificationSettingsView())),
            SettingsDestination(id: "appearance-settings", icon: "paintbrush.fill", title: "外観", destination: AnyView(AppearanceSettingsView()))
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

struct ProfileEditView: View {
    var body: some View {
        AppScaffold(
            title: "プロフィール",
            subtitle: "公開される情報を管理"
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard(title: "基本情報") {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ニックネーム")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("Miyu")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ひとこと")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("音楽で街の空気を集めたい")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                
                PrimaryButton(title: "保存") {}
            }
        }
    }
}

struct EncounterSettingsView: View {
    var body: some View {
        AppScaffold(
            title: "すれ違い設定",
            subtitle: "検知範囲と公開設定"
        ) {
            VStack(spacing: 24) {
                SectionCard(title: "検知範囲") {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("半径")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Text("30m")
                                .prototypeFont(size: 16, weight: .black, role: .data)
                                .foregroundStyle(PrototypeTheme.accent)
                        }
                        
                        Slider(value: .constant(0.6))
                            .tint(PrototypeTheme.accent)
                    }
                }
                
                SectionCard {
                    Toggle(isOn: .constant(true)) {
                        Text("相手から見つけやすくする")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .tint(PrototypeTheme.success)
                }
            }
        }
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        AppScaffold(
            title: "通知設定",
            subtitle: "受け取る通知を管理"
        ) {
            SectionCard {
                VStack(spacing: 20) {
                    Toggle(isOn: .constant(true)) {
                        Text("すれ違い通知")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Toggle(isOn: .constant(true)) {
                        Text("生成曲の通知")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
        }
    }
}

struct BlockMuteListView: View {
    var body: some View {
        AppScaffold(
            title: "ブロック / ミュート",
            subtitle: "公開範囲を調整"
        ) {
            VStack(spacing: 24) {
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
        AppScaffold(
            title: "音楽サービス連携",
            subtitle: "接続中のサービス"
        ) {
            SectionCard {
                VStack(spacing: 16) {
                    SettingRow(icon: "music.note.list", title: "Spotify", subtitle: "接続済み")
                    Divider()
                    SettingRow(icon: "music.note.house", title: "Apple Music", subtitle: "未接続")
                }
            }
        }
    }
}

struct AppearanceSettingsView: View {
    var body: some View {
        AppScaffold(
            title: "外観",
            subtitle: "表示テーマの設定"
        ) {
            SectionCard {
                VStack(alignment: .leading, spacing: 20) {
                    Label("ライトテーマ", systemImage: "sun.max.fill")
                        .font(.system(size: 16, weight: .bold))
                    Label("ダークテーマ", systemImage: "moon.fill")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}

struct DeleteAccountView: View {
    var body: some View {
        AppScaffold(
            title: "アカウント削除",
            subtitle: "削除前の最終確認"
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("この操作は元に戻せません")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(PrototypeTheme.error)
                        
                        Text("プロフィールや履歴など、すべてのデータが削除されます。")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                    }
                }
                
                Button(action: {}) {
                    Text("アカウントを削除")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(PrototypeTheme.error)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }
}

struct RestartOnboardingView: View {
    let restartOnboarding: () -> Void

    var body: some View {
        AppScaffold(
            title: "オンボーディング再表示",
            subtitle: "最初の案内をやり直す"
        ) {
            VStack(spacing: 28) {
                EmptyStateCard(
                    icon: "sparkles",
                    title: "最初から確認し直せます",
                    message: "設定フローをもう一度表示します。",
                    tint: PrototypeTheme.accent
                )
                
                PrimaryButton(title: "オンボーディングを再表示", systemImage: "arrow.counterclockwise") {
                    restartOnboarding()
                }
            }
        }
    }
}

struct OtherUserProfileStandaloneView: View {
    var body: some View {
        AppScaffold(
            title: "他ユーザープロフィール",
            subtitle: "相手からの見え方を確認"
        ) {
            OtherUserProfileCard()
        }
    }
}

struct EmptyStatesGalleryView: View {
    @State private var scenario: EmptyScenario = .firstEncounter

    var body: some View {
        AppScaffold(
            title: "空状態・エラー状態",
            subtitle: "例外ケースの表示確認"
        ) {
            VStack(alignment: .leading, spacing: 24) {
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
                        message: "人の多い場所を歩くと出会いやすくなります。",
                        tint: PrototypeTheme.accent
                    )
                case .inactive:
                    EmptyStateCard(
                        icon: "music.note.house",
                        title: "最近の出会いが少ないようです",
                        message: "検知範囲を広げると見つけやすくなります。",
                        tint: PrototypeTheme.warning
                    )
                case .searchEmpty:
                    EmptyStateCard(
                        icon: "magnifyingglass",
                        title: "検索結果がありません",
                        message: "キーワードを変えて試してください。",
                        tint: PrototypeTheme.textSecondary
                    )
                case .network:
                    EmptyStateCard(
                        icon: "wifi.exclamationmark",
                        title: "通信エラー",
                        message: "インターネット接続を確認してください。",
                        tint: PrototypeTheme.error
                    )
                case .bluetooth:
                    EmptyStateCard(
                        icon: "dot.radiowaves.left.and.right.slash",
                        title: "Bluetoothがオフです",
                        message: "近くの人を検知するにはBluetoothが必要です。",
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
        AppScaffold(
            title: "リアルタイム演出",
            subtitle: "状態変化の見え方を確認"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                Picker("状態", selection: $scenario) {
                    ForEach(RealtimeScenario.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                SectionCard {
                    VStack(spacing: 28) {
                        ZStack {
                            Circle()
                                .fill(PrototypeTheme.surfaceElevated)
                                .frame(width: 180, height: 180)
                            
                            Circle()
                                .fill(circleColor.opacity(0.15))
                                .frame(width: circleSize + 20, height: circleSize + 20)
                            
                            MockArtworkView(color: circleColor, symbol: "music.note", size: 90)
                                .shadow(color: circleColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        }
                        
                        VStack(spacing: 12) {
                            Text(statusTitle)
                                .font(.system(size: 24, weight: .black))
                            
                            Text(statusMessage)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var circleColor: Color {
        switch scenario {
        case .standby: return .gray
        case .approaching: return .yellow
        case .matched: return .green
        case .afterglow: return .indigo
        }
    }

    private var circleSize: CGFloat {
        switch scenario {
        case .standby: return 120
        case .approaching: return 140
        case .matched: return 160
        case .afterglow: return 130
        }
    }

    private var statusTitle: String {
        switch scenario {
        case .standby: return "検知を待っています"
        case .approaching: return "反応を検知しました"
        case .matched: return "すれ違いが成立しました"
        case .afterglow: return "余韻を表示しています"
        }
    }

    private var statusMessage: String {
        switch scenario {
        case .standby: return "近くのビーコンを探しています。"
        case .approaching: return "近くに誰かがいます。"
        case .matched: return "歌詞の断片を受け取りました。"
        case .afterglow: return "出会いの余韻を穏やかに見せます。"
        }
    }
}

struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(PrototypeTheme.warning)
            
            Text("オフライン")
                .prototypeFont(size: 12, weight: .black, role: .data)
                .foregroundStyle(PrototypeTheme.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(PrototypeTheme.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct FirstEncounterEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            EmptyStateCard(
                icon: "figure.walk",
                title: "まだすれ違いがありません",
                message: "最初の出会いを待っています。",
                tint: PrototypeTheme.accent
            )
        }
    }
}

struct WeeklyMusicCollageView: View {
    let tracks: [Track]

    private var visibleTracks: [Track] { Array(tracks.prefix(7)) }

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(60), spacing: 12), count: 4)

        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(visibleTracks) { track in
                NavigationLink {
                    EncounterListView()
                } label: {
                    MockArtworkView(color: track.color, symbol: "music.note", size: 60)
                }
                .buttonStyle(.plain)
            }

            if tracks.count > visibleTracks.count {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(PrototypeTheme.surfaceElevated)
                        .frame(width: 60, height: 60)
                    Text("+\(tracks.count - visibleTracks.count)")
                        .prototypeFont(size: 16, weight: .black, role: .data)
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }
            }
        }
    }
}

struct SummaryMetricCard: View {
    let title: String
    let count: Int
    let zeroMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(PrototypeTheme.textSecondary)
                .kerning(1.0)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(count > 0 ? PrototypeTheme.accent : PrototypeTheme.textPrimary)
                Text("人")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textTertiary)
            }

            if count == 0 {
                Text(zeroMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(count > 0 ? PrototypeTheme.surface : PrototypeTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct TrackSelectionRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 16) {
            MockArtworkView(color: track.color, symbol: "music.note", size: 52)
                .shadow(color: track.color.opacity(0.15), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(track.artist)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PrototypeTheme.textTertiary)
        }
    }
}

struct EncounterRow: View {
    let encounter: Encounter

    var body: some View {
        HStack(spacing: 16) {
            MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 52)
                .shadow(color: encounter.track.color.opacity(0.15), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(encounter.track.title)
                    .font(PrototypeTheme.Typography.Encounter.cardTitle)
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .lineLimit(1)
                
                Text(encounter.track.artist)
                    .font(PrototypeTheme.Typography.Encounter.body)
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(encounter.userName)
                    .font(PrototypeTheme.Typography.Encounter.meta)
                    .bold()
                    .foregroundStyle(PrototypeTheme.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(encounter.relativeTime)
                        .prototypeFont(size: 11, weight: .medium, role: .data)
                }
                .foregroundStyle(PrototypeTheme.textTertiary)
            }
        }
        .padding(16)
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(PrototypeTheme.accent.opacity(0.1))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PrototypeTheme.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(PrototypeTheme.success)
        }
        .padding(16)
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct OtherUserProfileCard: View {
    var body: some View {
        SectionCard {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(PrototypeTheme.surfaceElevated)
                        .frame(width: 90, height: 90)
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }
                
                VStack(spacing: 8) {
                    Text("Airi")
                        .font(.system(size: 24, weight: .black))
                    Text("夜の散歩とシティポップが好き")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 12) {
                    SecondaryButton(title: "ミュート", systemImage: "speaker.slash.fill") {}
                    SecondaryButton(title: "通報", systemImage: "flag.fill") {}
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}
