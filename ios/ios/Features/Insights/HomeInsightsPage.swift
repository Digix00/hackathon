import SwiftUI

struct HomeInsightsPage: View {
    let state: HomeScreenState

    private var trackInsights: [TrackInsight] {
        TrackInsight.build(from: state.recentEncounters)
    }

    private var artistInsights: [ArtistInsight] {
        ArtistInsight.build(from: state.recentEncounters)
    }

    private var peopleInsights: [PersonInsight] {
        PersonInsight.build(from: state.recentEncounters)
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
            VStack(alignment: .leading, spacing: 56) { // Increased spacing
                jacketHistorySection

                if let topTrack {
                    heroInsightSection(trackInsight: topTrack)
                }

                if !peopleInsights.isEmpty {
                    connectedPeopleSection
                }

                if !artistInsights.isEmpty {
                    connectedArtistsSection
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
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
    }

    private var connectedPeopleSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionEyebrow("MOST CONNECTED PEOPLE")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(peopleInsights.prefix(5)) { insight in
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(insight.representativeColor.opacity(0.15))
                                    .frame(width: 90, height: 90)

                                AsyncImage(url: URL(string: insight.avatarURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(insight.representativeColor.opacity(0.5))
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .shadow(color: insight.representativeColor.opacity(0.15), radius: 15, x: 0, y: 8)
                            }

                            VStack(spacing: 6) {
                                Text(insight.name)
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .lineLimit(1)

                                Text("\(insight.encounterCount) CONNECTS")
                                    .prototypeFont(size: 9, weight: .black, role: .data)
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .kerning(1.2)
                            }
                        }
                        .frame(width: 100)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
            }
            .padding(.horizontal, -4)
        }
    }

    private var connectedArtistsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionEyebrow("MOST CONNECTED ARTISTS")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(artistInsights.prefix(5)) { insight in
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(insight.representativeColor.opacity(0.15))
                                    .frame(width: 90, height: 90)

                                ArtworkPlaceholderView(
                                    color: insight.representativeColor,
                                    symbol: "person.fill",
                                    size: 80,
                                    artwork: insight.representativeArtwork
                                )
                                .clipShape(Circle())
                                .shadow(color: insight.representativeColor.opacity(0.15), radius: 15, x: 0, y: 8)
                            }

                            VStack(spacing: 6) {
                                Text(insight.name)
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .lineLimit(1)

                                Text("\(insight.encounterCount) CONNECTS")
                                    .prototypeFont(size: 9, weight: .black, role: .data)
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .kerning(1.2)
                            }
                        }
                        .frame(width: 100)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 10)
            }
            .padding(.horizontal, -4)
        }
    }

    private var jacketHistorySection: some View {
        VStack(alignment: .leading, spacing: 20) { // Increased spacing
            sectionEyebrow("JACKET HISTORY")
            HeroJacketCollageView(tracks: state.weeklyTracks)
                .padding(.horizontal, -24)
        }
    }

    private func heroInsightSection(trackInsight: TrackInsight) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            sectionEyebrow("MOST CONNECTIVE TRACK")

            VStack(alignment: .center, spacing: 28) {
                ArtworkPlaceholderView(
                    color: trackInsight.track.color,
                    symbol: "music.note",
                    size: 180, // Larger artwork
                    artwork: trackInsight.track.artwork
                )
                .shadow(color: trackInsight.track.color.opacity(0.2), radius: 30, x: 0, y: 15)
                .rotationEffect(.degrees(-3))

                VStack(spacing: 8) {
                    Text(trackInsight.track.title)
                        .font(PrototypeTheme.Typography.font(size: 32, weight: .black, role: .primary))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(trackInsight.track.artist)
                        .font(PrototypeTheme.Typography.font(size: 14, weight: .black, role: .data))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .kerning(1.6)
                }

                HStack(spacing: 32) {
                    metricValueOnly(title: "ENCOUNTERS", value: "\(trackInsight.encounterCount)", color: trackInsight.track.color)
                    metricValueOnly(title: "PEOPLE", value: "\(trackInsight.uniquePeopleCount)", color: PrototypeTheme.info)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(PrototypeTheme.surface.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(trackInsight.track.color.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    private func metricValueOnly(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 36, weight: .black))
                .foregroundStyle(color)
            Text(title)
                .prototypeFont(size: 9, weight: .black, role: .data)
                .foregroundStyle(PrototypeTheme.textTertiary)
                .kerning(1.2)
        }
    }

    private var connectedTracksSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionEyebrow("MOST CONNECTED TRACKS")

            VStack(spacing: 20) {
                ForEach(Array(trackInsights.prefix(3).enumerated()), id: \.element.id) { index, insight in
                    HStack(spacing: 20) {
                        ArtworkPlaceholderView(
                            color: insight.track.color,
                            symbol: "music.note",
                            size: 64,
                            artwork: insight.track.artwork
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.track.title)
                                .font(.system(size: 18, weight: .black))
                                .foregroundStyle(PrototypeTheme.textPrimary)

                            Text(insight.track.artist)
                                .font(PrototypeTheme.Typography.font(size: 11, weight: .black, role: .data))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }

                        Spacer()

                        Text("\(insight.uniquePeopleCount)")
                            .font(.system(size: 20, weight: .black))
                            .foregroundStyle(insight.track.color)
                    }
                    .padding(16)
                    .background(PrototypeTheme.surface.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        }
    }

    private var repeatTracksSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionEyebrow("REPEAT TRACKS")

            HStack(spacing: 16) {
                ForEach(Array(repeatTrackInsights.prefix(2).enumerated()), id: \.element.id) { _, insight in
                    VStack(alignment: .leading, spacing: 16) {
                        ArtworkPlaceholderView(
                            color: insight.track.color,
                            symbol: "waveform",
                            size: 60,
                            artwork: insight.track.artwork
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.track.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .lineLimit(1)

                            Text("\(insight.repeatCount) REPEATS")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(insight.track.color)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PrototypeTheme.surface.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
        }
    }

    private var timeMapSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionEyebrow("TRACK TIME MAP")

            VStack(spacing: 12) {
                ForEach(timeBuckets) { bucket in
                    HStack(spacing: 16) {
                        Text(bucket.label.uppercased())
                            .prototypeFont(size: 10, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .frame(width: 80, alignment: .leading)

                        if let leadTrack = bucket.topTrack {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(leadTrack.track.color)
                                    .frame(width: 8, height: 8)

                                Text(leadTrack.track.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        Text("\(bucket.encounterCount)")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(PrototypeTheme.surface.opacity(0.3))
                    .clipShape(Capsule())
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
                            ArtworkPlaceholderView(color: track.color, symbol: "music.note", size: 260, artwork: track.artwork)
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

private struct PersonInsight: Identifiable {
    let name: String
    let avatarURL: String?
    let encounterCount: Int
    let representativeColor: Color
    let uniqueTracks: Int

    var id: String { name }

    static func build(from encounters: [Encounter]) -> [PersonInsight] {
        let grouped = Dictionary(grouping: encounters, by: { $0.userName })

        return grouped.map { name, personEncounters in
            let trackIds = Set(personEncounters.map { $0.track.id })
            return PersonInsight(
                name: name,
                avatarURL: personEncounters.first?.userAvatarURL,
                encounterCount: personEncounters.count,
                representativeColor: personEncounters.first?.track.color ?? PrototypeTheme.accent,
                uniqueTracks: trackIds.count
            )
        }
        .sorted { $0.encounterCount > $1.encounterCount }
    }
}

private struct ArtistInsight: Identifiable {
    let name: String
    let encounterCount: Int
    let representativeColor: Color
    let representativeArtwork: String?
    let uniqueTracks: Int

    var id: String { name }

    static func build(from encounters: [Encounter]) -> [ArtistInsight] {
        let grouped = Dictionary(grouping: encounters, by: { $0.track.artist })

        return grouped.map { name, artistEncounters in
            let trackIds = Set(artistEncounters.map { $0.track.id })
            return ArtistInsight(
                name: name,
                encounterCount: artistEncounters.count,
                representativeColor: artistEncounters.first?.track.color ?? PrototypeTheme.accent,
                representativeArtwork: artistEncounters.first?.track.artwork,
                uniqueTracks: trackIds.count
            )
        }
        .sorted { $0.encounterCount > $1.encounterCount }
    }
}
