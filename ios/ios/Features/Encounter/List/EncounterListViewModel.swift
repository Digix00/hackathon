import Combine
import SwiftUI

@MainActor
final class EncounterListViewModel: ObservableObject {
    @Published private(set) var encounters: [Encounter] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient
    private var hasLoaded = false
    private var encounterDetails: [String: Encounter] = [:]

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func loadIfNeeded() {
        guard !hasLoaded, !isLoading else { return }
        Task { await loadEncounters() }
    }

    func refresh() {
        Task { await loadEncounters() }
    }

    func encounter(for id: String) -> Encounter? {
        if let detail = encounterDetails[id] {
            return detail
        }
        return encounters.first(where: { $0.id == id })
    }

    func loadDetail(id: String) {
        Task { await loadEncounterDetail(id: id) }
    }

    private func loadEncounters() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await client.listEncounters()
            let sorted = response.encounters.sorted { (lhs, rhs) in
                let lhsDate = lhs.occurredAt ?? .distantPast
                let rhsDate = rhs.occurredAt ?? .distantPast
                return lhsDate > rhsDate
            }
            let mapped = sorted.map(Self.mapListItem)
            encounters = Self.orderedBySection(mapped)
            hasLoaded = true
        } catch {
            errorMessage = "すれ違い履歴の取得に失敗しました"
            hasLoaded = false
        }
        isLoading = false
    }

    private func loadEncounterDetail(id: String) async {
        do {
            let detail = try await client.getEncounter(id: id)
            let mapped = Self.mapDetail(detail)
            encounterDetails[id] = mapped
            if let index = encounters.firstIndex(where: { $0.id == id }) {
                encounters[index] = mapped
            }
        } catch {
            // Detail load failure shouldn't block list display.
        }
    }
}

// MARK: - Mapping

private extension EncounterListViewModel {
    static func mapListItem(_ item: BackendEncounterListItem) -> Encounter {
        Encounter(
            id: item.id,
            userName: item.user.displayName,
            track: mapTrack(item.tracks.first, fallbackKey: item.id),
            relativeTime: relativeTime(from: item.occurredAt),
            lyric: "",
            occurredAt: item.occurredAt
        )
    }

    static func mapDetail(_ detail: BackendEncounterDetail) -> Encounter {
        Encounter(
            id: detail.id,
            userName: detail.user.displayName,
            track: mapTrack(detail.tracks.first, fallbackKey: detail.id),
            relativeTime: relativeTime(from: detail.occurredAt),
            lyric: "",
            occurredAt: detail.occurredAt
        )
    }

    static func orderedBySection(_ encounters: [Encounter]) -> [Encounter] {
        EncounterSection.allCases.flatMap { section in
            encounters.filter(section.includes)
        }
    }

    static func mapTrack(_ track: BackendEncounterTrack?, fallbackKey: String) -> Track {
        guard let track else {
            return Track(
                title: "不明な曲",
                artist: "不明",
                color: paletteColor(for: fallbackKey),
                artwork: nil
            )
        }

        return Track(
            title: track.title,
            artist: track.artistName,
            color: paletteColor(for: track.id),
            artwork: nil
        )
    }

    static func relativeTime(from occurredAt: Date?) -> String {
        guard let occurredAt else {
            return "時刻不明"
        }

        let calendar = Calendar.current
        if calendar.isDateInYesterday(occurredAt) {
            return "昨日"
        }
        if !calendar.isDateInToday(occurredAt) {
            let now = Date()
            let startOfOccurred = calendar.startOfDay(for: occurredAt)
            let startOfNow = calendar.startOfDay(for: now)
            let dayDelta = calendar.dateComponents([.day], from: startOfOccurred, to: startOfNow).day ?? 0
            if dayDelta > 1 {
                return "\(dayDelta)日前"
            }
            if dayDelta < 0 {
                return "近日"
            }
            return "昨日"
        }

        let now = Date()
        let interval = max(0, now.timeIntervalSince(occurredAt))
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "たった今"
        }
        if minutes < 60 {
            return "\(minutes)分前"
        }

        let hours = Int(Double(minutes) / 60.0)
        return "\(hours)時間前"
    }

    static func paletteColor(for key: String) -> Color {
        let palette: [Color] = [
            .indigo,
            .orange,
            .teal,
            .pink,
            .red,
            .green,
            .purple,
            .blue,
            .mint
        ]
        let index = Int(UInt(bitPattern: key.hashValue) % UInt(palette.count))
        return palette[index]
    }
}
