import SwiftUI

struct HomeInsightsPage: View {
    let state: HomeScreenState

    var body: some View {
        AppScaffold(
            title: "すれ違い情報",
            subtitle: "すれ違いで出会った音楽と相手の記録"
        ) {
            VStack(alignment: .leading, spacing: 28) {
                if state.isOffline {
                    OfflineBannerView()
                }

                SectionCard(title: "すれ違い") {
                    HStack(spacing: 14) {
                        SummaryMetricCard(
                            title: "今日",
                            count: state.todayEncounterCount,
                            zeroMessage: "まだありません"
                        )
                        SummaryMetricCard(
                            title: "今週",
                            count: state.weekEncounterCount,
                            zeroMessage: "まだありません"
                        )
                    }
                }

                if !state.weeklyTracks.isEmpty {
                    SectionCard(title: "出会った音楽") {
                        SectionHeader(title: "今週出会った音楽")
                        WeeklyMusicCollageView(tracks: state.weeklyTracks)
                    }
                }

                SectionCard(title: "最近のすれ違い") {
                    SectionHeader(title: "最近の出会い", showsAction: !state.recentEncounters.isEmpty)

                    if state.recentEncounters.isEmpty {
                        FirstEncounterEmptyState()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(state.recentEncounters.prefix(5)) { encounter in
                                NavigationLink {
                                    EncounterDetailView(encounter: encounter)
                                } label: {
                                    EncounterRow(encounter: encounter)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String
    var showsAction = true

    var body: some View {
        HStack {
            Text(title)
                .font(PrototypeTheme.Typography.Encounter.sectionTitle)
                .foregroundStyle(PrototypeTheme.textPrimary)
            Spacer()
            if showsAction {
                NavigationLink("すべて") {
                    EncounterListView()
                }
                .font(PrototypeTheme.Typography.Encounter.meta)
                .foregroundStyle(PrototypeTheme.accent)
            }
        }
    }
}
