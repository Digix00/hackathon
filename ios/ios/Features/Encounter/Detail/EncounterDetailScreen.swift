import SwiftUI
import UIKit

struct EncounterDetailView: View {
    @Environment(\.encounterNamespace) private var namespace
    let encounter: Encounter
    var onDismiss: (() -> Void)? = nil
    @State private var showsProfile = false
    @State private var showsLyricModal = false
    @State private var isMorphed = false // Controls the morph transition

    var body: some View {
        ZStack {
            PrototypeTheme.background
                .ignoresSafeArea()
                .opacity(isMorphed ? 1 : 0)

            // Morphing aura background
            morphingAuraView
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if isMorphed {
                    ScrollView(.vertical, showsIndicators: false) {
                        scrollContent
                    }
                } else {
                    scrollContent
                        .disabled(true)
                }
            }

            // Floating action buttons overlay
            floatingActions
        }
        .sheet(isPresented: $showsLyricModal) {
            LyricInputModalView()
        }
        .onAppear {
            // Trigger morph transition with elegant spring animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                isMorphed = true
            }
        }
        .onChange(of: isMorphed) { newValue in
            if !newValue {
                // Reverse animation when dismissing
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    // Animation handled by state change
                }
            }
        }
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        VStack(spacing: 0) {
            // Navigation Header (fades in after morph)
            HStack {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                isMorphed = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismiss?()
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
            .opacity(isMorphed ? 1 : 0)

            // Hero composition - morphs from list layout to detail layout
            VStack(spacing: isMorphed ? 60 : 32) {
                ZStack {
                    // Artwork with matched geometry
                    Group {
                        if let namespace = namespace {
                            MockArtworkView(
                                color: encounter.track.color,
                                symbol: "music.note",
                                size: isMorphed ? 300 : 80,
                                artwork: encounter.track.artwork
                            )
                            .matchedGeometryEffect(id: "artwork-\(encounter.id)", in: namespace)
                        } else {
                            MockArtworkView(
                                color: encounter.track.color,
                                symbol: "music.note",
                                size: isMorphed ? 300 : 80,
                                artwork: encounter.track.artwork
                            )
                        }
                    }
                    .shadow(
                        color: encounter.track.color.opacity(isMorphed ? 0.2 : 0.1),
                        radius: isMorphed ? 60 : 20,
                        x: 0,
                        y: isMorphed ? 30 : 10
                    )
                }
                .padding(.top, isMorphed ? 40 : 80)

                // Text content - morphs positions and styles
                VStack(spacing: isMorphed ? 24 : 12) {
                    VStack(spacing: isMorphed ? 8 : 4) {
                        // User name with matched geometry
                        Group {
                            if let namespace = namespace {
                                Text(encounter.userName)
                                    .matchedGeometryEffect(id: "userName-\(encounter.id)", in: namespace)
                            } else {
                                Text(encounter.userName)
                            }
                        }
                        .font(PrototypeTheme.Typography.font(
                            size: isMorphed ? 42 : 40,
                            weight: .black,
                            role: .primary
                        ))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .tracking(-1.5)
                        .multilineTextAlignment(.center)

                        // Subtitle (fades in after morph)
                        if isMorphed {
                            Text("との共鳴")
                                .font(PrototypeTheme.Typography.font(size: 14, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                                .transition(.opacity)
                        }
                    }

                    VStack(spacing: 4) {
                        // Track title with matched geometry
                        Group {
                            if let namespace = namespace {
                                Text(encounter.track.title)
                                    .matchedGeometryEffect(id: "trackTitle-\(encounter.id)", in: namespace)
                            } else {
                                Text(encounter.track.title)
                            }
                        }
                        .font(PrototypeTheme.Typography.font(
                            size: isMorphed ? 24 : 14,
                            weight: .bold,
                            role: .accent
                        ))
                        .italic()
                        .foregroundStyle(encounter.track.color)
                        .multilineTextAlignment(.center)

                        // Artist (fades in after morph)
                        if isMorphed {
                            Text(encounter.track.artist)
                                .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }

            // Lyric section (fades in after morph)
            if !encounter.lyric.isEmpty && isMorphed {
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

    // MARK: - Floating Actions Overlay

    private var floatingActions: some View {
        ZStack {
            if isMorphed {
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
                            showsLyricModal = true
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

    // MARK: - Morphing Aura View

    private var morphingAuraView: some View {
        ZStack {
            // Base gradient (final state)
            LinearGradient(
                colors: [
                    encounter.track.color.opacity(isMorphed ? 0.1 : 0.05),
                    PrototypeTheme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Morphing aura (fades out as we morph)
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
                        endRadius: isMorphed ? 250 : 150
                    )
                )
                .frame(
                    width: isMorphed ? 500 : 300,
                    height: isMorphed ? 500 : 300
                )
                .blur(radius: isMorphed ? 80 : 50)
                .opacity(isMorphed ? 0.6 : 1.0)
                .offset(y: isMorphed ? -100 : 0)
        }
    }
}
