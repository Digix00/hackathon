import Foundation

struct HomeScreenState: Hashable {
    let userName: String
    let featuredTrack: Track?
    let weeklyTracks: [Track]
    let recentEncounters: [Encounter]
    let todayEncounterCount: Int
    let weekEncounterCount: Int
    let isOffline: Bool
}

enum EmptyScenario: String, CaseIterable, Identifiable {
    case firstEncounter = "初回すれ違いゼロ"
    case inactive = "継続利用中ゼロ"
    case searchEmpty = "検索結果なし"
    case network = "通信エラー"
    case bluetooth = "Bluetooth 未許可"

    var id: String { rawValue }
}

enum RealtimeScenario: String, CaseIterable, Identifiable {
    case standby = "待機"
    case approaching = "予兆"
    case matched = "成立"
    case afterglow = "余韻"

    var id: String { rawValue }
}
