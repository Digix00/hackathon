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
            EncounterDetailHeader(encounter: encounter, isVisible: isMorphed) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    isMorphed = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss?()
                }
            }

            // Hero composition - morphs from list layout to detail layout
            VStack(spacing: isMorphed ? 60 : 32) {
                ZStack {
                    EncounterMatchedArtworkView(
                        encounter: encounter,
                        size: isMorphed ? 300 : 80,
                        shadowOpacity: isMorphed ? 0.2 : 0.1,
                        shadowRadius: isMorphed ? 60 : 20,
                        shadowYOffset: isMorphed ? 30 : 10,
                        namespace: namespace
                    )
                }
                .padding(.top, isMorphed ? 40 : 80)

                // Text content - morphs positions and styles
                VStack(spacing: isMorphed ? 24 : 12) {
                    VStack(spacing: isMorphed ? 8 : 4) {
                        EncounterMatchedUserNameView(
                            encounter: encounter,
                            fontSize: isMorphed ? 42 : 40,
                            namespace: namespace
                        )
                        .multilineTextAlignment(.center)

                        if isMorphed {
                            Text("との共鳴")
                                .font(PrototypeTheme.Typography.font(size: 14, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                                .transition(.opacity)
                        }
                    }

                    VStack(spacing: 4) {
                        EncounterMatchedTrackTitleView(
                            encounter: encounter,
                            fontSize: isMorphed ? 24 : 14,
                            namespace: namespace
                        )
                        .multilineTextAlignment(.center)

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

            if !encounter.lyric.isEmpty && isMorphed {
                EncounterLyricSection(encounter: encounter)
                .transition(.opacity.combined(with: .offset(y: 20)))
            }

            Spacer(minLength: 200)
        }
    }

    // MARK: - Floating Actions Overlay

    private var floatingActions: some View {
        ZStack {
            if isMorphed {
                EncounterPrimaryActions(encounter: encounter) {
                    showsLyricModal = true
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
