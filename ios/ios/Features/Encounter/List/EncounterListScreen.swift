import SwiftUI

struct EncounterListView: View {
    private enum DetailLayout {
        static let bottomActionsInset: CGFloat = 24
        static let bottomActionsTopPadding: CGFloat = 16
        static let contentBottomSpacing: CGFloat = 148
    }

    @Namespace private var encounterNamespace
    @Binding private var isDetailPresented: Bool
    @State private var selectedEncounter: Encounter?
    @State private var showDetailContent = false
    @SceneStorage("encounter.list.scrollTargetID") private var scrollTargetID: String?
    
    private let wheelItemHeight: CGFloat = 300
    private let wheelItemSpacing: CGFloat = 10

    private var encounters: [Encounter] {
        let previewEncounters = MockData.encountersWithoutLyrics + MockData.encounters
        return EncounterSection.allCases.flatMap { section in
            previewEncounters.filter(section.includes)
        }
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
        .onChange(of: selectedEncounter?.id) { _ in
            syncDetailPresentationState()
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        GeometryReader { geometry in
            let topPadding = geometry.safeAreaInsets.top

            ZStack {
                // Background
                ZStack {
                    PrototypeTheme.background.ignoresSafeArea()
                    DotGridBackground()
                        .opacity(0.15)
                }
                .opacity(selectedEncounter == nil ? 1 : 0)

                VStack(spacing: 0) {
                    listHeader(topPadding: topPadding)
                        .padding(.horizontal, 24)
                        .opacity(selectedEncounter == nil ? 1 : 0)
                    
                    GeometryReader { wheelGeometry in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: wheelItemSpacing) {
                                ForEach(Array(encounters.enumerated()), id: \.offset) { index, encounter in
                                    let isSelected = selectedEncounter?.id == encounter.id
                                    let isCentered = (scrollTargetID ?? encounters.first?.id) == encounter.id
                                    let isBefore = selectedEncounter.map { selected in
                                        encounters.firstIndex(where: { $0.id == selected.id })! >
                                        encounters.firstIndex(where: { $0.id == encounter.id })!
                                    } ?? false
                                    
                                    GeometryReader { itemGeometry in
                                        let metrics = wheelMetrics(itemGeometry: itemGeometry, wheelGeometry: wheelGeometry)
                                        
                                        Button {
                                            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                                                selectedEncounter = encounter
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
                                            .opacity(selectedEncounter != nil && !isSelected ? 0 : metrics.opacity)
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
                            .scrollTargetLayout()
                            .padding(.horizontal, 24)
                            .safeAreaPadding(.vertical, max((wheelGeometry.size.height - wheelItemHeight) / 2, 0))
                        }
                        .coordinateSpace(name: "encounterWheel")
                        .scrollPosition(id: $scrollTargetID, anchor: .center)
                        .scrollTargetBehavior(.viewAligned)
                        .scrollClipDisabled()
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private func listHeader(topPadding: CGFloat) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("つながり")
                    .font(PrototypeTheme.Typography.Product.screenTitle)
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .tracking(-0.5)
                
                Text("都市のノイズが生んだ、一期一会の旋律")
                    .font(PrototypeTheme.Typography.Product.subtitle)
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(PrototypeTheme.surfaceMuted.opacity(0.6))
                    .clipShape(Capsule())
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .padding(12)
                    .background(PrototypeTheme.surface)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.top, topPadding + 8)
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
        ZStack {
            // Keep background consistent - no flash
            Color.clear

            // Morphing aura background
            morphingAura(for: encounter)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Navigation Header
                    EncounterDetailHeader(encounter: encounter, isVisible: showDetailContent) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                            showDetailContent = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                                selectedEncounter = nil
                            }
                        }
                    }

                    // Hero composition
                    VStack(spacing: showDetailContent ? 60 : 32) {
                        EncounterMatchedArtworkView(
                            encounter: encounter,
                            size: showDetailContent ? 300 : 80,
                            shadowOpacity: showDetailContent ? 0.2 : 0.1,
                            shadowRadius: showDetailContent ? 60 : 20,
                            shadowYOffset: showDetailContent ? 30 : 10,
                            namespace: encounterNamespace
                        )
                        .padding(.top, showDetailContent ? 40 : 80)

                        // Text content
                        VStack(spacing: showDetailContent ? 24 : 12) {
                            VStack(spacing: showDetailContent ? 8 : 4) {
                                EncounterMatchedUserNameView(
                                    encounter: encounter,
                                    fontSize: showDetailContent ? 42 : 40,
                                    namespace: encounterNamespace
                                )
                                    .multilineTextAlignment(.center)

                                if showDetailContent {
                                    Text("との共鳴")
                                        .font(PrototypeTheme.Typography.font(size: 14, weight: .bold))
                                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                                        .transition(.opacity)
                                }
                            }

                            VStack(spacing: 4) {
                                EncounterMatchedTrackTitleView(
                                    encounter: encounter,
                                    fontSize: showDetailContent ? 24 : 14,
                                    namespace: encounterNamespace
                                )
                                    .multilineTextAlignment(.center)

                                if showDetailContent {
                                    Text(encounter.track.artist)
                                        .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                                        .foregroundStyle(PrototypeTheme.textSecondary)
                                        .transition(.opacity)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    }

                    // Lyric section
                    if !encounter.lyric.isEmpty && showDetailContent {
                        EncounterLyricSection(encounter: encounter)
                        .transition(.opacity.combined(with: .offset(y: 20)))
                    }

                    Spacer(minLength: DetailLayout.contentBottomSpacing)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showDetailContent {
                EncounterPrimaryActions(encounter: encounter) {}
                    .padding(.horizontal, 32)
                    .padding(.top, DetailLayout.bottomActionsTopPadding)
                    .padding(.bottom, DetailLayout.bottomActionsInset)
                    .transition(.opacity.combined(with: .offset(y: 20)))
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
        isDetailPresented = selectedEncounter != nil
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
