import SwiftUI

struct EncounterListView: View {
    @Namespace private var encounterNamespace
    @State private var selectedEncounter: Encounter?
    @State private var showDetailContent = false

    private var encounters: [Encounter] {
        let previewEncounters = MockData.encountersWithoutLyrics + MockData.encounters
        return EncounterSection.allCases.flatMap { section in
            previewEncounters.filter(section.includes)
        }
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

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Header - fades out when detail appears
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
                        .opacity(selectedEncounter == nil ? 1 : 0)

                        // Encounter list
                        VStack(alignment: .leading, spacing: 100) {
                            LazyVStack(spacing: 80) {
                                ForEach(Array(encounters.enumerated()), id: \.offset) { index, encounter in
                                    let isSelected = selectedEncounter?.id == encounter.id
                                    let isBefore = selectedEncounter.map { selected in
                                        encounters.firstIndex(where: { $0.id == selected.id })! >
                                        encounters.firstIndex(where: { $0.id == encounter.id })!
                                    } ?? false

                                    Button {
                                        withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                                            selectedEncounter = encounter
                                        }
                                        // Delay detail content appearance
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
                                        .opacity(selectedEncounter != nil && !isSelected ? 0 : 1)
                                        .offset(y: selectedEncounter != nil && !isSelected
                                            ? (isBefore ? -200 : 200)
                                            : 0)
                                    }
                                    .buttonStyle(EncounterScaleButtonStyle())
                                }
                            }
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 160)
                    }
                    .padding(.horizontal, 24)
                }
                .scrollContentBackground(.hidden)
            }
        }
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
                    HStack {
                        Button {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                                showDetailContent = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                                    selectedEncounter = nil
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .frame(width: 44, height: 44, alignment: .leading)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("CONNECTED MOMENT")
                                .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.5))
                                .tracking(2.0)

                            Text(encounter.relativeTime.uppercased())
                                .font(PrototypeTheme.Typography.font(size: 12, weight: .bold, role: .data))
                                .foregroundStyle(encounter.track.color)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .opacity(showDetailContent ? 1 : 0)

                    // Hero composition
                    VStack(spacing: showDetailContent ? 60 : 32) {
                        // Artwork
                        MockArtworkView(
                            color: encounter.track.color,
                            symbol: "music.note",
                            size: showDetailContent ? 300 : 80,
                            artwork: encounter.track.artwork
                        )
                        .matchedGeometryEffect(id: "artwork-\(encounter.id)", in: encounterNamespace)
                        .shadow(
                            color: encounter.track.color.opacity(showDetailContent ? 0.2 : 0.1),
                            radius: showDetailContent ? 60 : 20,
                            x: 0,
                            y: showDetailContent ? 30 : 10
                        )
                        .padding(.top, showDetailContent ? 40 : 80)

                        // Text content
                        VStack(spacing: showDetailContent ? 24 : 12) {
                            VStack(spacing: showDetailContent ? 8 : 4) {
                                Text(encounter.userName)
                                    .matchedGeometryEffect(id: "userName-\(encounter.id)", in: encounterNamespace)
                                    .font(PrototypeTheme.Typography.font(
                                        size: showDetailContent ? 42 : 40,
                                        weight: .black,
                                        role: .primary
                                    ))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .tracking(-1.5)
                                    .multilineTextAlignment(.center)

                                if showDetailContent {
                                    Text("との共鳴")
                                        .font(PrototypeTheme.Typography.font(size: 14, weight: .bold))
                                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                                        .transition(.opacity)
                                }
                            }

                            VStack(spacing: 4) {
                                Text(encounter.track.title)
                                    .matchedGeometryEffect(id: "trackTitle-\(encounter.id)", in: encounterNamespace)
                                    .font(PrototypeTheme.Typography.font(
                                        size: showDetailContent ? 24 : 14,
                                        weight: .bold,
                                        role: .accent
                                    ))
                                    .italic()
                                    .foregroundStyle(encounter.track.color)
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
                        VStack(alignment: .leading, spacing: 24) {
                            Text("記憶の断片")
                                .font(PrototypeTheme.Typography.font(size: 11, weight: .black, role: .data))
                                .foregroundStyle(encounter.track.color.opacity(0.6))
                                .kerning(3)
                                .padding(.leading, 8)

                            Text(encounter.lyric)
                                .font(PrototypeTheme.Typography.font(size: 28, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textPrimary.opacity(0.9))
                                .lineSpacing(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(40)
                                .background(
                                    ZStack {
                                        Color.white.opacity(0.01)
                                        encounter.track.color.opacity(0.03)
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 100)
                        .transition(.opacity.combined(with: .offset(y: 20)))
                    }

                    Spacer(minLength: 200)
                }
            }

            // Floating actions
            if showDetailContent {
                VStack {
                    Spacer()
                    HStack(spacing: 16) {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 72, height: 72)
                                .background(
                                    Circle()
                                        .fill(encounter.track.color)
                                        .shadow(color: encounter.track.color.opacity(0.3), radius: 20, x: 0, y: 10)
                                )
                        }

                        Button {
                            // Handle lyric input
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .bold))
                                Text("想いを刻む")
                                    .font(PrototypeTheme.Typography.font(size: 16, weight: .bold))
                            }
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(
                                Capsule()
                                    .fill(PrototypeTheme.surfaceElevated)
                                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
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
}

struct EncounterScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
