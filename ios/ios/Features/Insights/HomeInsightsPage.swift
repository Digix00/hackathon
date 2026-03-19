import SwiftUI

struct HomeInsightsPage: View {
    let state: HomeScreenState

    private var trackInsights: [TrackInsight] {
        TrackInsight.build(from: state.recentEncounters)
    }

    private var topTrack: TrackInsight? {
        trackInsights.first
    }

    private var repeatTrackInsights: [TrackInsight] {
        trackInsights.filter { $0.repeatCount > 0 }
    }

    private var timeBuckets: [TrackTimeInsight] {
        TrackTimeInsight.build(from: state.recentEncounters)
    }

    private var backgroundColors: [Color] {
        let prioritizedTracks = [topTrack?.track] + state.weeklyTracks.map(Optional.some)
        return Array(prioritizedTracks.compactMap { $0?.color }.prefix(4))
    }

    var body: some View {
        AppScaffold(
            title: "INSIGHTS",
            subtitle: "都市に漂う音楽の断片",
            customBackground: AnyView(InsightsBackground(colors: backgroundColors))
        ) {
            VStack(alignment: .leading, spacing: 36) {
                jacketHistorySection

                if let topTrack {
                    heroInsightSection(trackInsight: topTrack)
                }

                if !trackInsights.isEmpty {
                    connectedTracksSection
                }

                if !repeatTrackInsights.isEmpty {
                    repeatTracksSection
                }

                if !timeBuckets.isEmpty {
                    timeMapSection
                }
            }
            .padding(.bottom, 120)
        }
    }

    private var jacketHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionEyebrow("JACKET HISTORY")
            HeroJacketCollageView(tracks: state.weeklyTracks)
                .padding(.horizontal, -24)
        }
    }

    private func heroInsightSection(trackInsight: TrackInsight) -> some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top, spacing: 20) {
                    MockArtworkView(
                        color: trackInsight.track.color,
                        symbol: "music.note",
                        size: 96,
                        artwork: trackInsight.track.artwork
                    )
                    .shadow(color: trackInsight.track.color.opacity(0.22), radius: 22, x: 0, y: 12)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("MOST CONNECTIVE TRACK")
                            .prototypeFont(size: 10, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .kerning(1.8)

                        Text(trackInsight.track.title)
                            .font(PrototypeTheme.Typography.font(size: 26, weight: .black, role: .primary))
                            .foregroundStyle(PrototypeTheme.textPrimary)

                        Text(trackInsight.track.artist)
                            .font(PrototypeTheme.Typography.font(size: 13, weight: .black, role: .data))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .kerning(1.4)

                        if let person = trackInsight.topPerson {
                            Text(person)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(trackInsight.track.color)
                                .padding(.top, 2)
                        }
                    }
                }

                HStack(spacing: 12) {
                    insightMetricCard(
                        title: "ENCOUNTERS",
                        value: "\(trackInsight.encounterCount)",
                        tint: trackInsight.track.color
                    )
                    insightMetricCard(
                        title: "PEOPLE",
                        value: "\(trackInsight.uniquePeopleCount)",
                        tint: PrototypeTheme.info
                    )
                    insightMetricCard(
                        title: "REPEATS",
                        value: "\(trackInsight.repeatCount)",
                        tint: PrototypeTheme.success
                    )
                }

                if !trackInsight.people.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(Array(trackInsight.people.prefix(4).enumerated()), id: \.offset) { index, person in
                            Text(person)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(chipBackgroundColor(at: index, track: trackInsight.track))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var connectedTracksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionEyebrow("MOST CONNECTED TRACKS")

            VStack(spacing: 14) {
                ForEach(Array(trackInsights.prefix(3).enumerated()), id: \.element.id) { index, insight in
                    SectionCard {
                        HStack(alignment: .center, spacing: 16) {
                            MockArtworkView(
                                color: insight.track.color,
                                symbol: "music.note",
                                size: 72,
                                artwork: insight.track.artwork
                            )
                            .rotationEffect(.degrees(index.isMultiple(of: 2) ? -3 : 3))

                            VStack(alignment: .leading, spacing: 8) {
                                Text(insight.track.title)
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundStyle(PrototypeTheme.textPrimary)

                                Text(insight.track.artist)
                                    .font(PrototypeTheme.Typography.font(size: 11, weight: .black, role: .data))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .kerning(1.3)

                                Text(relationshipLabel(for: insight))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(insight.track.color)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var repeatTracksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionEyebrow("REPEAT TRACKS")

            VStack(spacing: 14) {
                ForEach(Array(repeatTrackInsights.prefix(3).enumerated()), id: \.element.id) { _, insight in
                    SectionCard {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 14) {
                                MockArtworkView(
                                    color: insight.track.color,
                                    symbol: "waveform",
                                    size: 64,
                                    artwork: insight.track.artwork
                                )

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(insight.track.title)
                                        .font(.system(size: 19, weight: .black))
                                        .foregroundStyle(PrototypeTheme.textPrimary)

                                    Text("\(insight.repeatCount) REPEATS")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(PrototypeTheme.textSecondary)
                                }

                                Spacer()
                            }

                            if let person = insight.topPerson {
                                Text(person)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(insight.track.color)
                            }
                        }
                    }
                }
            }
        }
    }

    private var timeMapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionEyebrow("TRACK TIME MAP")

            VStack(spacing: 14) {
                ForEach(timeBuckets) { bucket in
                    SectionCard {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                Text(bucket.label.uppercased())
                                    .prototypeFont(size: 11, weight: .black, role: .data)
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .kerning(1.8)

                                Spacer()

                                Text("\(bucket.encounterCount) ENCOUNTERS")
                                    .prototypeFont(size: 10, weight: .black, role: .data)
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }

                            if let leadTrack = bucket.topTrack {
                                HStack(spacing: 14) {
                                    MockArtworkView(
                                        color: leadTrack.track.color,
                                        symbol: "clock",
                                        size: 58,
                                        artwork: leadTrack.track.artwork
                                    )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(leadTrack.track.title)
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(PrototypeTheme.textPrimary)

                                        Text(bucket.descriptionPrefix)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(PrototypeTheme.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionEyebrow(_ text: String) -> some View {
        Text(text)
            .prototypeFont(size: 11, weight: .black, role: .data)
            .foregroundStyle(PrototypeTheme.textSecondary)
            .kerning(2.0)
            .padding(.horizontal, 2)
    }

    private func insightMetricCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .prototypeFont(size: 9, weight: .black, role: .data)
                .foregroundStyle(PrototypeTheme.textSecondary)
                .kerning(1.4)

            Text(value)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(PrototypeTheme.surfaceMuted.opacity(0.8))
        )
    }

    private func relationshipLabel(for insight: TrackInsight) -> String {
        if insight.repeatCount > 1 {
            return "再会を引き寄せる曲"
        }
        if insight.uniquePeopleCount > 1 {
            return "新しい接続が多い曲"
        }
        return "最初の接点になった曲"
    }

    private func chipBackgroundColor(at index: Int, track: Track) -> Color {
        index.isMultiple(of: 2) ? track.color.opacity(0.16) : PrototypeTheme.surfaceMuted
    }
}

private struct HeroJacketCollageView: View {
    let tracks: [Track]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -24) {
                    ForEach(Array(tracks.prefix(8).enumerated()), id: \.offset) { index, track in
                        VStack(alignment: .leading, spacing: 20) {
                            MockArtworkView(color: track.color, symbol: "music.note", size: 260, artwork: track.artwork)
                                .shadow(color: Color.black.opacity(0.12), radius: 30, x: 0, y: 20)
                                .shadow(color: track.color.opacity(0.15), radius: 40, x: 0, y: 30)
                                .rotationEffect(.degrees(Double(index.isMultiple(of: 2) ? -4 : 4)))

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
        .frame(height: 440)
    }
}

private struct TrackInsight: Identifiable {
    let track: Track
    let encounterCount: Int
    let uniquePeopleCount: Int
    let repeatCount: Int
    let people: [String]
    let topPerson: String?

    var id: String { track.id }

    static func build(from encounters: [Encounter]) -> [TrackInsight] {
        let grouped = Dictionary(grouping: encounters, by: \.track)

        return grouped.compactMap { track, groupedEncounters in
            let peopleCounts = groupedEncounters.reduce(into: [String: Int]()) { partialResult, encounter in
                partialResult[encounter.userName, default: 0] += 1
            }

            let sortedPeople = peopleCounts
                .sorted {
                    if $0.value == $1.value {
                        return $0.key < $1.key
                    }
                    return $0.value > $1.value
                }

            return TrackInsight(
                track: track,
                encounterCount: groupedEncounters.count,
                uniquePeopleCount: peopleCounts.count,
                repeatCount: max(0, groupedEncounters.count - peopleCounts.count),
                people: sortedPeople.map(\.key),
                topPerson: sortedPeople.first?.key
            )
        }
        .sorted {
            if $0.uniquePeopleCount == $1.uniquePeopleCount {
                if $0.encounterCount == $1.encounterCount {
                    return $0.track.title < $1.track.title
                }
                return $0.encounterCount > $1.encounterCount
            }
            return $0.uniquePeopleCount > $1.uniquePeopleCount
        }
    }
}

private struct TrackTimeInsight: Identifiable {
    let bucket: TimeBucket
    let encounterCount: Int
    let supportingTracks: [TrackInsight]

    var id: String { bucket.rawValue }
    var label: String { bucket.label }
    var descriptionPrefix: String { bucket.descriptionPrefix }
    var topTrack: TrackInsight? { supportingTracks.first }

    static func build(from encounters: [Encounter]) -> [TrackTimeInsight] {
        let grouped = Dictionary(grouping: encounters, by: { TimeBucket.from(relativeTime: $0.relativeTime) })

        return TimeBucket.allCases.compactMap { bucket in
            guard let bucketEncounters = grouped[bucket], !bucketEncounters.isEmpty else {
                return nil
            }

            return TrackTimeInsight(
                bucket: bucket,
                encounterCount: bucketEncounters.count,
                supportingTracks: Array(TrackInsight.build(from: bucketEncounters).prefix(2))
            )
        }
    }
}

private enum TimeBucket: String, CaseIterable {
    case now
    case recent
    case yesterday
    case earlier

    var label: String {
        switch self {
        case .now:
            return "just now"
        case .recent:
            return "today"
        case .yesterday:
            return "yesterday"
        case .earlier:
            return "archive"
        }
    }

    var descriptionPrefix: String {
        switch self {
        case .now:
            return "直近"
        case .recent:
            return "今日"
        case .yesterday:
            return "昨日"
        case .earlier:
            return "少し前"
        }
    }

    static func from(relativeTime: String) -> TimeBucket {
        if relativeTime == "たった今" {
            return .now
        }
        if relativeTime == "昨日" {
            return .yesterday
        }
        if relativeTime == "以前" ||
            relativeTime.hasSuffix("日前") ||
            relativeTime.hasSuffix("週間前") ||
            relativeTime.hasSuffix("か月前") ||
            relativeTime.hasSuffix("年前") {
            return .earlier
        }
        return .recent
    }
}
