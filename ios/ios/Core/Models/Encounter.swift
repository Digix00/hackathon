import Foundation

struct Encounter: Identifiable, Hashable {
    let id: String
    let userName: String
    let track: Track
    let relativeTime: String
    let lyric: String
    let occurredAt: Date?

    init(id: String? = nil, userName: String, track: Track, relativeTime: String, lyric: String, occurredAt: Date? = nil) {
        self.id = id ?? "\(userName)-\(track.id)-\(relativeTime)-\(lyric)"
        self.userName = userName
        self.track = track
        self.relativeTime = relativeTime
        self.lyric = lyric
        self.occurredAt = occurredAt
    }

    var happenedYesterday: Bool {
        relativeTime == "昨日"
    }

    var happenedToday: Bool {
        !happenedYesterday && !happenedEarlier
    }

    var happenedEarlier: Bool {
        if relativeTime == "以前" ||
            relativeTime.hasSuffix("日前") ||
            relativeTime.hasSuffix("週間前") ||
            relativeTime.hasSuffix("か月前") ||
            relativeTime.hasSuffix("年前") {
            return true
        }

        return relativeTime == "不明"
    }
}

enum EncounterSection: String, CaseIterable, Identifiable {
    case today = "今日"
    case yesterday = "昨日"
    case earlier = "以前"

    var id: String { rawValue }

    func includes(_ encounter: Encounter) -> Bool {
        switch self {
        case .today:
            return encounter.happenedToday
        case .yesterday:
            return encounter.happenedYesterday
        case .earlier:
            return encounter.happenedEarlier
        }
    }
}
