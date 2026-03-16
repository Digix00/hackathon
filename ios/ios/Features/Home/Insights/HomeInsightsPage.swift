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
                
                // --- 1. THE HERO COLLAGE ---
                if !state.weeklyTracks.isEmpty {
                    HeroJacketCollageView(tracks: state.weeklyTracks)
                        .padding(.horizontal, -24)
                        .padding(.top, 20)
                        .padding(.bottom, 80)
                }

                // --- 2. RECENT ENCOUNTERS ---
                VStack(alignment: .leading, spacing: 40) {
                    Text("最近のすれ違い")
                        .font(PrototypeTheme.Typography.font(size: 22, weight: .black, role: .primary))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .tracking(-0.5)

                    if state.recentEncounters.isEmpty {
                        FirstEncounterEmptyState()
                    } else {
                        VStack(spacing: 28) {
                            ForEach(state.recentEncounters.prefix(7)) { encounter in
                                NavigationLink {
                                    EncounterDetailView(encounter: encounter)
                                } label: {
                                    HeroEncounterRow(encounter: encounter)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    
                    NavigationLink {
                        EncounterListView()
                    } label: {
                        HStack(spacing: 12) {
                            Text("すべての出会いを見る")
                                .font(PrototypeTheme.Typography.font(size: 15, weight: .bold, role: .primary))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .black))
                        }
                        .foregroundStyle(PrototypeTheme.accent)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(PrototypeTheme.accent.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 20)
                }
                .padding(.bottom, 120)
            }
        }
    }
}

// MARK: - Components

private struct HeroJacketCollageView: View {
    let tracks: [Track]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -70) {
                ForEach(Array(tracks.prefix(8).enumerated()), id: \.offset) { index, track in
                    VStack(alignment: .leading, spacing: 24) {
                        MockArtworkView(color: track.color, symbol: "music.note", size: 300)
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
            .padding(.horizontal, 48)
            .padding(.vertical, 40)
        }
    }
}

private struct HeroEncounterRow: View {
    let encounter: Encounter
    
    var body: some View {
        HStack(spacing: 24) {
            MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 68)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: encounter.track.color.opacity(0.2), radius: 15, x: 0, y: 8)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(encounter.track.title)
                    .font(PrototypeTheme.Typography.font(size: 18, weight: .bold, role: .primary))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .lineLimit(1)
                
                Text(encounter.track.artist)
                    .font(PrototypeTheme.Typography.font(size: 15, weight: .medium, role: .primary))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(encounter.relativeTime)
                    .font(PrototypeTheme.Typography.font(size: 12, weight: .bold, role: .data))
                    .foregroundStyle(PrototypeTheme.textTertiary)
                
                Circle()
                    .fill(encounter.track.color.opacity(0.6))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
