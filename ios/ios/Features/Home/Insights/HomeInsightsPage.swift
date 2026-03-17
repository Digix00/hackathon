import SwiftUI

struct HomeInsightsPage: View {
    let state: HomeScreenState

    var body: some View {
        AppScaffold(
            title: "INSIGHTS",
            subtitle: "都市に漂う音楽の断片",
            customBackground: AnyView(
                MemoryBlurBackground(colors: state.weeklyTracks.map(\.color))
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
                        VStack(alignment: .leading, spacing: 24) {
                            MockArtworkView(color: track.color, symbol: "music.note", size: 300, artwork: track.artwork)
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                .shadow(color: Color.black.opacity(0.35), radius: 40, x: 0, y: 25)
                                .rotationEffect(.degrees(Double(index % 2 == 0 ? -5 : 5)))
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(track.title)
                                    .font(PrototypeTheme.Typography.font(size: 20, weight: .black, role: .primary))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .lineLimit(1)
                                Text(track.artist)
                                    .font(PrototypeTheme.Typography.font(size: 16, weight: .bold, role: .primary))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(.leading, 16)
                        }
                        .zIndex(Double(tracks.count - index))
                    }
                }
                .frame(minWidth: max(geometry.size.width - 96, 0), alignment: .center)
                .padding(.horizontal, 48)
                .padding(.vertical, 40)
            }
        }
        .frame(height: 460)
    }
}
