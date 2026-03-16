import SwiftUI

struct HomeInsightsPage: View {
    let state: HomeScreenState

    var body: some View {
        AppScaffold(
            title: "INSIGHTS",
            subtitle: "都市に漂う音楽の断片"
        ) {
            ZStack {
                // --- BACKGROUND: MEMORY BLUR ---
                // 数値が消えたことで、この背景の色彩がより重要になります
                MemoryBlurBackground(tracks: state.weeklyTracks)
                
                VStack(alignment: .leading, spacing: 64) {
                    if state.isOffline {
                        OfflineBannerView()
                    }

                    // --- TOP STATUS ---
                    // 数値の代わりに、現在の「状態」と「位置」を静かに配置
                    HStack(alignment: .top) {
                        CoordinateDisplayView()
                        Spacer()
                        BeaconStatusView()
                    }
                    .padding(.top, 8)

                    // --- COLLAGE SECTION ---
                    // 出会った音楽をアートとして見せる
                    if !state.weeklyTracks.isEmpty {
                        VStack(alignment: .leading, spacing: 28) {
                            HStack(alignment: .lastTextBaseline) {
                                Text("最近出会った音楽")
                                    .font(PrototypeTheme.Typography.font(size: 18, weight: .bold, role: .primary))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .tracking(0.5)
                                Spacer()
                                NavigationLink("すべて見る") {
                                    EncounterListView()
                                }
                                .font(PrototypeTheme.Typography.font(size: 12, weight: .bold, role: .primary))
                                .foregroundStyle(PrototypeTheme.accent)
                            }

                            WeeklyMusicCollageView(tracks: state.weeklyTracks)
                        }
                    }

                    // --- RECENT ENCOUNTERS ---
                    // 出会いのリスト
                    VStack(alignment: .leading, spacing: 28) {
                        Text("最近のすれ違い")
                            .font(PrototypeTheme.Typography.font(size: 18, weight: .bold, role: .primary))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .tracking(0.5)

                        if state.recentEncounters.isEmpty {
                            FirstEncounterEmptyState()
                        } else {
                            VStack(spacing: 16) {
                                ForEach(state.recentEncounters.prefix(7)) { encounter in
                                    NavigationLink {
                                        EncounterDetailView(encounter: encounter)
                                    } label: {
                                        InsightEncounterRow(encounter: encounter)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

// MARK: - Components

private struct MemoryBlurBackground: View {
    let tracks: [Track]
    
    var body: some View {
        ZStack {
            PrototypeTheme.background.ignoresSafeArea()
            
            // ジャケットの断片をより広範囲に、より淡く漂わせる
            ForEach(Array(tracks.prefix(12).enumerated()), id: \.offset) { index, track in
                MockArtworkView(color: track.color, symbol: "music.note", size: 240)
                    .clipShape(Circle())
                    .offset(x: randomOffset(for: index).x, y: randomOffset(for: index).y)
                    .opacity(0.25)
                    .blur(radius: 70)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func randomOffset(for index: Int) -> CGPoint {
        let offsets: [CGPoint] = [
            CGPoint(x: -150, y: -300),
            CGPoint(x: 200, y: -150),
            CGPoint(x: -100, y: 200),
            CGPoint(x: 220, y: 400),
            CGPoint(x: -180, y: -80),
            CGPoint(x: 120, y: 500),
            CGPoint(x: -250, y: 150),
            CGPoint(x: 80, y: -400),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 180, y: 100),
            CGPoint(x: -120, y: -200),
            CGPoint(x: 150, y: 300)
        ]
        return offsets[index % offsets.count]
    }
}

private struct BeaconStatusView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(PrototypeTheme.accent)
                .frame(width: 6, height: 6)
                .opacity(isAnimating ? 1.0 : 0.3)
                .scaleEffect(isAnimating ? 1.2 : 0.8)

            Text("BEACON ACTIVE")
                .font(PrototypeTheme.Typography.font(size: 9, weight: .black, role: .data))
                .foregroundStyle(PrototypeTheme.textPrimary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(PrototypeTheme.accent.opacity(0.1))
        .clipShape(Capsule())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

private struct CoordinateDisplayView: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("LAT")
                    .font(PrototypeTheme.Typography.font(size: 7, weight: .black, role: .data))
                    .foregroundStyle(PrototypeTheme.textTertiary)
                Text("35.6812° N")
                    .font(PrototypeTheme.Typography.font(size: 10, weight: .bold, role: .data))
            }
            
            Rectangle()
                .fill(PrototypeTheme.textTertiary.opacity(0.3))
                .frame(width: 1, height: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text("LNG")
                    .font(PrototypeTheme.Typography.font(size: 7, weight: .black, role: .data))
                    .foregroundStyle(PrototypeTheme.textTertiary)
                Text("139.7671° E")
                    .font(PrototypeTheme.Typography.font(size: 10, weight: .bold, role: .data))
            }
        }
        .foregroundStyle(PrototypeTheme.textSecondary)
        .opacity(0.8)
    }
}

private struct InsightEncounterRow: View {
    let encounter: Encounter

    var body: some View {
        HStack(spacing: 16) {
            MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: encounter.track.color.opacity(0.1), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(encounter.track.title)
                    .font(PrototypeTheme.Typography.font(size: 16, weight: .bold, role: .primary))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .lineLimit(1)

                Text(encounter.track.artist)
                    .font(PrototypeTheme.Typography.font(size: 14, weight: .medium, role: .primary))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(encounter.relativeTime)
                    .font(PrototypeTheme.Typography.font(size: 11, weight: .bold, role: .data))
                    .foregroundStyle(PrototypeTheme.textTertiary)

                Circle()
                    .fill(encounter.track.color.opacity(0.5))
                    .frame(width: 5, height: 5)
            }
        }
        .padding(16)
        .background(
            GlassmorphicCard { EmptyView() }
                .opacity(0.7)
        )
    }
}
