import SwiftUI

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
            HapticsService.impact(.medium)
            selectedSurface = .library
        } else if translation > threshold, selectedSurface == .library {
            HapticsService.impact(.medium)
            selectedSurface = .track
        }
    }
}
