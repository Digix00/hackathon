import Foundation

struct Encounter: Identifiable, Hashable {
    let id: String
    let userName: String
    let track: Track
    let relativeTime: String
    let lyric: String

    var happenedToday: Bool {
        relativeTime == "たった今"
            || relativeTime.hasSuffix("分前")
            || relativeTime.hasSuffix("時間前")
            || relativeTime == "近日"
    }

    var happenedYesterday: Bool {
        relativeTime == "昨日"
    }

    var happenedEarlier: Bool {
        !happenedToday && !happenedYesterday
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
