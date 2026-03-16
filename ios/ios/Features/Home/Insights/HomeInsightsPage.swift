import SwiftUI

struct HomeInsightsPage: View {
    let state: HomeScreenState

    var body: some View {
        AppScaffold(
            title: "INSIGHTS",
            subtitle: nil
        ) {
            ZStack {
                // --- BACKGROUND: MEMORY BLUR ---
                MemoryBlurBackground(tracks: state.weeklyTracks)
                
                VStack(alignment: .leading, spacing: 56) {
                    if state.isOffline {
                        OfflineBannerView()
                    }

                    // --- HERO SECTION ---
                    VStack(alignment: .leading, spacing: 32) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("今日のすれ違い")
                                    .font(PrototypeTheme.Typography.font(size: 12, weight: .black, role: .primary))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .kerning(1.2)

                                HStack(alignment: .lastTextBaseline, spacing: 8) {
                                    Text("\(state.todayEncounterCount)")
                                        .font(PrototypeTheme.Typography.font(size: 100, weight: .black, role: .primary))
                                        .foregroundStyle(state.todayEncounterCount > 0 ? PrototypeTheme.accent : PrototypeTheme.textPrimary)
                                        .tracking(-4)

                                    Text("人")
                                        .font(PrototypeTheme.Typography.font(size: 18, weight: .bold, role: .primary))
                                        .foregroundStyle(PrototypeTheme.textSecondary)
                                        .padding(.bottom, 18)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 16) {
                                BeaconStatusView()
                                CoordinateDisplayView()
                            }
                        }

                        // Stats Row (Japanese labels)
                        HStack(spacing: 20) {
                            SummaryMetricHero(
                                label: "今週の合計",
                                count: state.weekEncounterCount,
                                unit: "人"
                            )
                            SummaryMetricHero(
                                label: "新しい音楽",
                                count: state.weeklyTracks.count,
                                unit: "曲"
                            )
                        }
                    }
                    .padding(.top, 12)

                    // --- COLLAGE SECTION ---
                    if !state.weeklyTracks.isEmpty {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack(alignment: .lastTextBaseline) {
                                Text("最近出会った音楽")
                                    .font(PrototypeTheme.Typography.font(size: 16, weight: .bold, role: .primary))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
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
                    VStack(alignment: .leading, spacing: 24) {
                        Text("最近のすれ違い")
                            .font(PrototypeTheme.Typography.font(size: 16, weight: .bold, role: .primary))
                            .foregroundStyle(PrototypeTheme.textPrimary)

                        if state.recentEncounters.isEmpty {
                            FirstEncounterEmptyState()
                        } else {
                            VStack(spacing: 16) {
                                ForEach(state.recentEncounters.prefix(5)) { encounter in
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
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Components

/// 背景に曲のジャケットを散りばめて強めにぼかしたビュー
private struct MemoryBlurBackground: View {
    let tracks: [Track]
    
    var body: some View {
        ZStack {
            // ベースの暗がり
            PrototypeTheme.background.ignoresSafeArea()
            
            // ジャケットの断片
            ForEach(Array(tracks.prefix(8).enumerated()), id: \.offset) { index, track in
                MockArtworkView(color: track.color, symbol: "music.note", size: 200)
                    .clipShape(Circle())
                    .offset(x: randomOffset(for: index).x, y: randomOffset(for: index).y)
                    .opacity(0.3)
                    .blur(radius: 60) // 強めのぼかし
            }
        }
        .allowsHitTesting(false)
    }
    
    private func randomOffset(for index: Int) -> CGPoint {
        let offsets: [CGPoint] = [
            CGPoint(x: -120, y: -200),
            CGPoint(x: 150, y: -100),
            CGPoint(x: -80, y: 150),
            CGPoint(x: 180, y: 300),
            CGPoint(x: -150, y: -50),
            CGPoint(x: 100, y: 400),
            CGPoint(x: -200, y: 100),
            CGPoint(x: 50, y: -300)
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
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

private struct CoordinateDisplayView: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("35.6812° N")
            Text("139.7671° E")
        }
        .font(PrototypeTheme.Typography.font(size: 10, weight: .medium, role: .data))
        .foregroundStyle(PrototypeTheme.textTertiary)
        .opacity(0.6)
    }
}

private struct SummaryMetricHero: View {
    let label: String
    let count: Int
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(PrototypeTheme.Typography.font(size: 11, weight: .bold, role: .primary))
                .foregroundStyle(PrototypeTheme.textSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(count)")
                    .font(PrototypeTheme.Typography.font(size: 28, weight: .black, role: .primary))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                Text(unit)
                    .font(PrototypeTheme.Typography.font(size: 12, weight: .bold, role: .primary))
                    .foregroundStyle(PrototypeTheme.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            GlassmorphicCard { EmptyView() }
                .opacity(0.6)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct InsightEncounterRow: View {
    let encounter: Encounter

    var body: some View {
        HStack(spacing: 16) {
            MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 52)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: encounter.track.color.opacity(0.2), radius: 10, x: 0, y: 5)

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
                    .fill(encounter.track.color)
                    .frame(width: 5, height: 5)
            }
        }
        .padding(16)
        .background(
            GlassmorphicCard { EmptyView() }
                .opacity(0.8)
        )
    }
}
