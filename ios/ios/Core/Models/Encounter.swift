import Foundation

struct Encounter: Identifiable, Hashable {
    let id: String
    let userName: String
    let track: Track
    let relativeTime: String
    let lyric: String

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
