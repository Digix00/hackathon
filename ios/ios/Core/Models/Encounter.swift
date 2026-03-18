import Foundation

struct Encounter: Identifiable, Hashable {
    let id: String
    let userName: String
    let track: Track
    let relativeTime: String
    let lyric: String

    init(id: String? = nil, userName: String, track: Track, relativeTime: String, lyric: String) {
        self.id = id ?? "\(userName)-\(track.id)-\(relativeTime)-\(lyric)"
        self.userName = userName
        self.track = track
        self.relativeTime = relativeTime
        self.lyric = lyric
    }

    var happenedYesterday: Bool {
        relativeTime == "昨日"
    }
}

enum EncounterSection: String, CaseIterable, Identifiable {
    case today = "今日"
    case yesterday = "昨日"

    var id: String { rawValue }

    func includes(_ encounter: Encounter) -> Bool {
        switch self {
        case .today:
            return !encounter.happenedYesterday
        case .yesterday:
            return encounter.happenedYesterday
        }
    }
}
