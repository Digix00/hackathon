import SwiftUI

struct HomeInsightsPage: View {
    let state: HomeScreenState

    var body: some View {
        AppScaffold(
            title: "INSIGHTS",
            subtitle: "都市に漂う音楽の断片",
            customBackground: AnyView(
                InsightsBackground(colors: state.weeklyTracks.map(\.color))
            )
        ) {
            VStack(alignment: .leading, spacing: 0) {
                heroCollageSection
            }
            .padding(.bottom, 120)
        }
    }

    @ViewBuilder
    private var heroCollageSection: some View {
        if !state.weeklyTracks.isEmpty {
            HeroJacketCollageView(tracks: state.weeklyTracks)
                .padding(.horizontal, -24)
                .padding(.top, 20)
                .padding(.bottom, 40)
        }
    }
}

// MARK: - Components

private struct HeroJacketCollageView: View {
    let tracks: [Track]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -24) {
                    ForEach(Array(tracks.prefix(8).enumerated()), id: \.offset) { index, track in
                        VStack(alignment: .leading, spacing: 20) {
                            MockArtworkView(color: track.color, symbol: "music.note", size: 300, artwork: track.artwork)
                                // Sophisticated Shadow: Base soft shadow + subtle ambient occlusion
                                .shadow(color: Color.black.opacity(0.12), radius: 30, x: 0, y: 20)
                                .shadow(color: track.color.opacity(0.15), radius: 40, x: 0, y: 30) // Subtle color glow
                                .rotationEffect(.degrees(Double(index % 2 == 0 ? -4 : 4)))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(track.title)
                                    .font(PrototypeTheme.Typography.font(size: 22, weight: .black, role: .primary))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .tracking(-0.5)
                                    .lineLimit(1)
                                
                                Text(track.artist.uppercased())
                                    .font(PrototypeTheme.Typography.font(size: 12, weight: .black, role: .data))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .tracking(2.0)
                                    .lineLimit(1)
                            }
                            .padding(.leading, 12)
                        }
                        .zIndex(Double(tracks.count - index))
                    }
                }
                .frame(minWidth: max(geometry.size.width - 96, 0), alignment: .center)
                .padding(.horizontal, 48)
                .padding(.vertical, 60)
            }
        }
        .frame(height: 500)
    }
}
