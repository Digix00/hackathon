import SwiftUI

struct MainPrototypeView: View {
    private enum Layout {
        static let trackToLibrarySwipeThreshold: CGFloat = 90
        static let libraryToTrackSwipeThreshold: CGFloat = 180
        static let libraryToTrackPredictedThreshold: CGFloat = 240
        static let dragResponseFactor: CGFloat = 0.9
        static let backgroundScale: CGFloat = 0.95
        static let inactiveOpacity: Double = 0.5
        static let libraryFooterReserve: CGFloat = 84
    }

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
            case .insights: return "気配"
            case .history: return "つながり"
            case .songs: return "旋律"
            case .profile: return "自分"
            }
        }

        var symbol: String {
            switch self {
            case .insights: return "dot.radiowaves.left.and.right"
            case .history: return "hands.sparkles" // More emotional symbol for connection
            case .songs: return "waveform"
            case .profile: return "person.crop.circle"
            }
        }
    }

    @State private var selectedSurface: Surface = .track
    @State private var selectedLibraryTab: LibraryTab = .insights
    @State private var isEncounterDetailPresented = false
    @GestureState private var verticalDragOffset: CGFloat = 0
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator
    let restartOnboarding: () -> Void
    @Namespace private var homeNamespace

    var body: some View {
        GeometryReader { proxy in
            let screenHeight = proxy.size.height

            ZStack {
                trackSurface
                    .offset(y: trackSurfaceOffset(screenHeight: screenHeight))
                    .opacity(isShowingTrackSurface ? 1.0 : Layout.inactiveOpacity)
                    .scaleEffect(isShowingTrackSurface ? 1.0 : Layout.backgroundScale)

                librarySurface(bottomSafeArea: proxy.safeAreaInsets.bottom)
                    .environment(\.topSafeAreaInset, proxy.safeAreaInsets.top)
                    .environment(
                        \.bottomSafeAreaInset,
                        libraryBottomInset(bottomSafeArea: proxy.safeAreaInsets.bottom)
                    )
                    .offset(y: librarySurfaceOffset(screenHeight: screenHeight))
                    .opacity(isShowingTrackSurface ? Layout.inactiveOpacity : 1.0)
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
                        handleVerticalSwipe(value)
                    }
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedSurface)
            .environment(\.homeNamespace, homeNamespace)
        }
        .background(PrototypeTheme.background)
        .ignoresSafeArea()
        .tint(PrototypeTheme.accent)
    }

    private var homeState: HomeScreenState {
        let encounters = bleCoordinator.encounters
        let featuredTrack = encounters.first?.track
        let weeklyTracks = uniqueTracks(from: encounters.map(\.track)).prefix(8)
        let todayCount = encounters.filter { $0.happenedToday }.count

        return HomeScreenState(
            userName: "Miyu",
            featuredTrack: featuredTrack,
            weeklyTracks: Array(weeklyTracks),
            recentEncounters: encounters,
            todayEncounterCount: todayCount,
            weekEncounterCount: encounters.count,
            isOffline: bleCoordinator.encounterErrorMessage != nil && encounters.isEmpty
        )
    }

    private func uniqueTracks(from tracks: [Track]) -> [Track] {
        var seen: Set<String> = []

        return tracks.filter { track in
            seen.insert(track.id).inserted
        }
    }

    private var isShowingTrackSurface: Bool {
        selectedSurface == .track
    }
    
    private var trackSurface: some View {
        navigationContainer {
            HomePage(
                state: homeState,
                isMotionActive: isShowingTrackSurface
            )
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .environment(\.topSafeAreaInset, 0)
        .environment(\.bottomSafeAreaInset, 0)
    }

    private func librarySurface(bottomSafeArea: CGFloat) -> some View {
        TabView(selection: $selectedLibraryTab) {
            navigationContainer {
                HomeInsightsPage(
                    state: homeState
                )
            }
            .tag(LibraryTab.insights)

            navigationContainer {
                EncounterListView(isDetailPresented: $isEncounterDetailPresented)
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
                    handleVerticalSwipe(value)
                }
        )
        .overlay(alignment: .bottom) {
            if shouldShowLibraryFooter {
                LibraryFooter(
                    selectedTab: $selectedLibraryTab,
                    tabs: LibraryTab.allCases
                )
                .environment(\.bottomSafeAreaInset, bottomSafeArea)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var shouldShowLibraryFooter: Bool {
        selectedSurface == .library && !(selectedLibraryTab == .history && isEncounterDetailPresented)
    }

    private func libraryBottomInset(bottomSafeArea: CGFloat) -> CGFloat {
        shouldShowLibraryFooter ? bottomSafeArea + Layout.libraryFooterReserve : bottomSafeArea
    }

    private var dragOffset: CGFloat {
        switch selectedSurface {
        case .track:
            return min(0, verticalDragOffset * Layout.dragResponseFactor)
        case .library:
            return max(0, verticalDragOffset * Layout.dragResponseFactor)
        }
    }

    private func trackSurfaceOffset(screenHeight: CGFloat) -> CGFloat {
        isShowingTrackSurface ? dragOffset : -screenHeight + dragOffset
    }

    private func librarySurfaceOffset(screenHeight: CGFloat) -> CGFloat {
        isShowingTrackSurface ? screenHeight + dragOffset : dragOffset
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

    private func handleVerticalSwipe(_ value: DragGesture.Value) {
        let translation = value.translation.height
        let predicted = value.predictedEndTranslation.height

        if translation < -Layout.trackToLibrarySwipeThreshold, selectedSurface == .track {
            HapticsService.impact(.medium)
            selectedSurface = .library
        } else if
            selectedSurface == .library &&
            translation > Layout.libraryToTrackSwipeThreshold &&
            predicted > Layout.libraryToTrackPredictedThreshold
        {
            HapticsService.impact(.medium)
            selectedSurface = .track
        }
    }
}
