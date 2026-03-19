import SwiftUI

struct EncounterListView: View {
    private enum DetailLayout {
        static let bottomActionsInset: CGFloat = 24
        static let bottomActionsTopPadding: CGFloat = 16
        static let contentBottomSpacing: CGFloat = 148
    }

    private struct DetailMetrics {
        let isTablet: Bool
        let horizontalPadding: CGFloat
        let readableWidth: CGFloat
        let artworkSize: CGFloat
        let heroSpacing: CGFloat
        let artworkTopPadding: CGFloat
        let heroTextSpacing: CGFloat
        let detailLabelSpacing: CGFloat
        let userNameFontSize: CGFloat
        let trackTitleFontSize: CGFloat
        let supportingFontSize: CGFloat

        init(availableWidth: CGFloat) {
            let isNarrowPhone = availableWidth < 390
            isTablet = availableWidth >= 700

            horizontalPadding = isNarrowPhone ? 20 : (isTablet ? 40 : 32)
            readableWidth = isTablet ? min(availableWidth - 80, 620) : max(availableWidth - (horizontalPadding * 2), 0)
            artworkSize = isNarrowPhone ? 240 : (isTablet ? 320 : 300)
            heroSpacing = isNarrowPhone ? 44 : (isTablet ? 68 : 60)
            artworkTopPadding = isNarrowPhone ? 28 : 40
            heroTextSpacing = isNarrowPhone ? 18 : 24
            detailLabelSpacing = isNarrowPhone ? 6 : 8
            userNameFontSize = isNarrowPhone ? 34 : (isTablet ? 46 : 42)
            trackTitleFontSize = isNarrowPhone ? 20 : (isTablet ? 26 : 24)
            supportingFontSize = isNarrowPhone ? 13 : 14
        }
    }

    @Namespace private var encounterNamespace
    @Binding private var isDetailPresented: Bool
    @State private var selectedEncounterID: String?
    @State private var showDetailContent = false
    @State private var lyricComposerEncounter: Encounter?
    @SceneStorage("encounter.list.scrollTargetID") private var scrollTargetID: String?
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator
    
    private let wheelItemHeight: CGFloat = 300
    private let wheelItemSpacing: CGFloat = 10

    private var encounters: [Encounter] {
        bleCoordinator.encounters
    }

    private var totalEncountersCount: Int {
        encounters.count
    }

    private var weeklyEncountersCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        return encounters.filter { encounter in
            guard let date = encounter.occurredAt else { return true }
            return date >= sevenDaysAgo
        }.count
    }

    private var selectedEncounter: Encounter? {
        guard let selectedEncounterID else { return nil }
        return encounters.first(where: { $0.id == selectedEncounterID })
    }

    init(isDetailPresented: Binding<Bool> = .constant(false)) {
        _isDetailPresented = isDetailPresented
    }

    var body: some View {
        ZStack {
            // Persistent background - never flashes
            PrototypeTheme.background.ignoresSafeArea()

            // List mode - always present during morph
            listContent

            // Detail mode - overlays when selected
            if let selected = selectedEncounter {
                detailContent(for: selected)
                    .zIndex(1)
            }
        }
        .background(PrototypeTheme.background.ignoresSafeArea())
        .environment(\.encounterNamespace, encounterNamespace)
        .onAppear {
            if scrollTargetID == nil {
                scrollTargetID = encounters.first?.id
            }
            syncDetailPresentationState()
        }
        .onChange(of: selectedEncounterID) {
            syncDetailPresentationState()
        }
        .onChange(of: bleCoordinator.encounters.map(\.id)) { _, ids in
            if let target = scrollTargetID, !ids.contains(target) {
                scrollTargetID = ids.first
            } else if scrollTargetID == nil {
                scrollTargetID = ids.first
            }
            guard let selectedEncounterID, !ids.contains(selectedEncounterID) else { return }
            self.selectedEncounterID = nil
        }
        .sheet(item: $lyricComposerEncounter) { encounter in
            LyricComposerSheet(encounter: encounter)
                .environmentObject(bleCoordinator)
        }
    }

    // MARK: - List Content

    private struct EncounterStatsHeader: View {
        let totalCount: Int
        let weeklyCount: Int

        @State private var isAnimating = false

        var body: some View {
            VStack(alignment: .leading, spacing: 12) { // Tightened spacing
                // Secondary Stat (Subtle & Data-focused)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("TOTAL SPECIMENS")
                        .prototypeFont(size: 10, weight: .black, role: .data)
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .kerning(1.8)
                    
                    Text("\(totalCount)")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }
                .padding(.leading, 4)
                .opacity(isAnimating ? 1.0 : 0)
                .offset(x: isAnimating ? 0 : -10)

                // Primary Stat (Large & Airy)
                HStack(alignment: .bottom, spacing: 16) { // Slightly tighter spacing
                    Text("\(weeklyCount)")
                        .font(.system(size: 84, weight: .black))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .tracking(-4)
                        .contentTransition(.numericText())

                    VStack(alignment: .leading, spacing: 2) { // Tightened inner vertical spacing
                        Text("ENCOUNTERS")
                            .prototypeFont(size: 10, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .kerning(2.0)

                        Text("THIS WEEK")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(PrototypeTheme.textTertiary)
                            .kerning(1.0)
                    }
                    .padding(.bottom, 20)
                }
                .opacity(isAnimating ? 1.0 : 0)
                .offset(y: isAnimating ? 0 : 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .onAppear {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }

    private var listContent: some View {
        GeometryReader { geometry in
            let topPadding = geometry.safeAreaInsets.top

            if encounters.isEmpty {
                EncounterEmptyStateView(
                    errorMessage: bleCoordinator.encounterErrorMessage,
                    isLoading: bleCoordinator.isLoadingEncounters,
                    onRefresh: {
                        bleCoordinator.refreshEncounters()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {

                ZStack {
                    // Background
                    ZStack {
                        PrototypeTheme.background.ignoresSafeArea()
                        DotGridBackground()
                            .opacity(0.15)
                        
                        if selectedEncounterID == nil {
                            GeometryReader { g in
                                // Position stats compactly near the top
                                let headerAreaHeight = (g.size.height - wheelItemHeight) / 2
                                if headerAreaHeight > 100 {
                                    EncounterStatsHeader(
                                        totalCount: totalEncountersCount,
                                        weeklyCount: weeklyEncountersCount
                                    )
                                    .frame(height: headerAreaHeight, alignment: .top) // Top align
                                    .offset(y: g.safeAreaInsets.top + 20) // Precise offset from notch
                                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                                }
                            }
                        }
                    }
                    .opacity(selectedEncounterID == nil ? 1 : 0)

                    VStack(spacing: 0) {
                        GeometryReader { wheelGeometry in
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: wheelItemSpacing) {
                                    ForEach(Array(encounters.enumerated()), id: \.element.id) { index, encounter in
                                        let isSelected = selectedEncounter?.id == encounter.id
                                        let isCentered = (scrollTargetID ?? encounters.first?.id) == encounter.id
                                        let isBefore = isEncounterBeforeSelected(encounter)

                                        GeometryReader { itemGeometry in
                                            let metrics = wheelMetrics(itemGeometry: itemGeometry, wheelGeometry: wheelGeometry)
                                            let rowOpacity: Double = {
                                                if selectedEncounter != nil && !isSelected { return 0 }
                                                if isSelected && showDetailContent { return 0 }
                                                return metrics.opacity
                                            }()

                                            Button {
                                                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                                                    selectedEncounterID = encounter.id
                                                }
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                                                        showDetailContent = true
                                                    }
                                                }
                                            } label: {
                                                EncounterRow(
                                                    encounter: encounter,
                                                    isFixed: index == 0,
                                                    hideMatchedElements: isSelected && selectedEncounter != nil
                                                )
                                                .scaleEffect(metrics.scale)
                                                .opacity(rowOpacity)
                                                .blur(radius: metrics.blur)
                                                .saturation(metrics.saturation)
                                                .offset(
                                                    y: selectedEncounter != nil && !isSelected
                                                        ? (isBefore ? -200 : 200)
                                                        : metrics.verticalOffset
                                                )
                                                .zIndex(metrics.zIndex)
                                            }
                                            .buttonStyle(EncounterScaleButtonStyle())
                                            .disabled(!isCentered || selectedEncounter != nil)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        }
                                        .frame(height: wheelItemHeight)
                                        .id(encounter.id)
                                    }
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, 24)
                            .safeAreaPadding(.vertical, max((wheelGeometry.size.height - wheelItemHeight) / 2, 0))
                        }
                        .coordinateSpace(name: "encounterWheel")
                        .scrollPosition(id: $scrollTargetID, anchor: .center)
                        .scrollTargetBehavior(.viewAligned)
                        .scrollClipDisabled()
                    }
                    .padding(.top, topPadding + 8)
                }
            }
        }
        .task {
            if bleCoordinator.encounters.isEmpty && !bleCoordinator.isLoadingEncounters {
                bleCoordinator.refreshEncounters()
            }
        }
    }
    
    private func wheelMetrics(itemGeometry: GeometryProxy, wheelGeometry: GeometryProxy) -> WheelMetrics {
        let frame = itemGeometry.frame(in: .named("encounterWheel"))
        let viewportCenter = wheelGeometry.size.height / 2
        let itemCenter = frame.midY
        let distance = abs(itemCenter - viewportCenter)
        let normalizedDistance = min(distance / (wheelItemHeight * 0.8), 1)
        let eased = 1 - pow(1 - normalizedDistance, 2.4)
        
        return WheelMetrics(
            scale: 1.03 - (eased * 0.28),
            opacity: 1.0 - (eased * 0.62),
            blur: eased * 2.2,
            saturation: 1.02 - (eased * 0.34),
            verticalOffset: eased * 26,
            zIndex: 1.0 - Double(normalizedDistance)
        )
    }

    private func isEncounterBeforeSelected(_ encounter: Encounter) -> Bool {
        guard let selected = selectedEncounter,
              let selectedIndex = encounters.firstIndex(where: { $0.id == selected.id }),
              let encounterIndex = encounters.firstIndex(where: { $0.id == encounter.id }) else {
            return false
        }

        return selectedIndex > encounterIndex
    }
    
    private struct WheelMetrics {
        let scale: CGFloat
        let opacity: CGFloat
        let blur: CGFloat
        let saturation: CGFloat
        let verticalOffset: CGFloat
        let zIndex: Double
    }

    // MARK: - Detail Content

    private func detailContent(for encounter: Encounter) -> some View {
        GeometryReader { proxy in
            let globalWidth = proxy.frame(in: .global).width
            let layoutWidth = globalWidth > 0 ? min(proxy.size.width, globalWidth) : proxy.size.width
            let metrics = DetailMetrics(availableWidth: layoutWidth)
            let contentWidth = max(layoutWidth - (metrics.horizontalPadding * 2), 0)
            let heroWidth = min(contentWidth, 520)
            let sectionWidth = metrics.isTablet ? min(metrics.readableWidth, contentWidth) : layoutWidth
            let transitionNamespace: Namespace.ID? = encounterNamespace

            ZStack {
                // Keep background consistent - no flash
                Color.clear

                // Morphing aura background
                morphingAura(for: encounter)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero composition
                        VStack(spacing: showDetailContent ? metrics.heroSpacing : 32) {
                            EncounterMatchedArtworkView(
                                encounter: encounter,
                                size: showDetailContent ? metrics.artworkSize : 80,
                                shadowOpacity: showDetailContent ? 0.2 : 0.1,
                                shadowRadius: showDetailContent ? 60 : 20,
                                shadowYOffset: showDetailContent ? 30 : 10,
                                namespace: transitionNamespace
                            )
                            .padding(.top, showDetailContent ? metrics.artworkTopPadding : 80)

                            // Text content
                            VStack(spacing: showDetailContent ? metrics.heroTextSpacing : 12) {
                                VStack(spacing: showDetailContent ? metrics.detailLabelSpacing : 4) {
                                    EncounterMatchedUserNameView(
                                        encounter: encounter,
                                        fontSize: showDetailContent ? metrics.userNameFontSize : 40,
                                        namespace: transitionNamespace
                                    )
                                    .multilineTextAlignment(.center)

                                    if showDetailContent {
                                        Text("との共鳴")
                                            .font(PrototypeTheme.Typography.font(size: metrics.supportingFontSize, weight: .bold))
                                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                                            .transition(.opacity)
                                    }
                                }

                                VStack(spacing: 4) {
                                    EncounterMatchedTrackTitleView(
                                        encounter: encounter,
                                        fontSize: showDetailContent ? metrics.trackTitleFontSize : 14,
                                        namespace: transitionNamespace
                                    )
                                    .multilineTextAlignment(.center)

                                    if showDetailContent {
                                        Text(encounter.track.artist)
                                            .font(PrototypeTheme.Typography.font(size: metrics.supportingFontSize, weight: .medium))
                                            .foregroundStyle(PrototypeTheme.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .transition(.opacity)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: heroWidth)
                        .frame(maxWidth: .infinity)

                        if !encounter.lyric.isEmpty && showDetailContent {
                            EncounterLyricSection(encounter: encounter)
                                .frame(maxWidth: sectionWidth)
                                .frame(maxWidth: .infinity)
                                .transition(.opacity.combined(with: .offset(y: 20)))
                        }

                        if showDetailContent {
                            EncounterCommentsSection(encounter: encounter)
                                .frame(maxWidth: sectionWidth)
                                .frame(maxWidth: .infinity)
                                .transition(.opacity.combined(with: .offset(y: 20)))
                        }

                        Spacer(minLength: DetailLayout.contentBottomSpacing)
                    }
                    .frame(width: layoutWidth)
                    .padding(.top, 16)
                }
            }
            .frame(width: layoutWidth, height: proxy.size.height, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .safeAreaInset(edge: .top, spacing: 0) {
                EncounterDetailHeader(
                    encounter: encounter,
                    isVisible: showDetailContent,
                    horizontalPadding: metrics.horizontalPadding
                ) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                        showDetailContent = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                            selectedEncounterID = nil
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if showDetailContent {
                    EncounterPrimaryActions(encounter: encounter) {
                        lyricComposerEncounter = encounter
                    }
                    .frame(maxWidth: sectionWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, metrics.isTablet ? 0 : metrics.horizontalPadding)
                    .padding(.top, DetailLayout.bottomActionsTopPadding)
                    .padding(.bottom, DetailLayout.bottomActionsInset)
                    .transition(.opacity.combined(with: .offset(y: 20)))
                }
            }
        }
    }

    // MARK: - Morphing Aura

    private func morphingAura(for encounter: Encounter) -> some View {
        ZStack {
            // Subtle gradient that grows
            LinearGradient(
                colors: [
                    encounter.track.color.opacity(showDetailContent ? 0.1 : 0.0),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Main morphing aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            encounter.track.color.opacity(0.15),
                            encounter.track.color.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: showDetailContent ? 250 : 150
                    )
                )
                .frame(
                    width: showDetailContent ? 500 : 300,
                    height: showDetailContent ? 500 : 300
                )
                .blur(radius: showDetailContent ? 80 : 50)
                .opacity(showDetailContent ? 0.6 : 1.0)
                .offset(y: showDetailContent ? -100 : 0)
        }
    }

    private func syncDetailPresentationState() {
        isDetailPresented = selectedEncounterID != nil
        if selectedEncounterID == nil {
            showDetailContent = false
        }
    }
}

struct EncounterScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
