import SwiftUI

struct Track: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let color: Color
}

struct Encounter: Identifiable, Hashable {
    let id = UUID()
    let userName: String
    let track: Track
    let relativeTime: String
    let lyric: String
}

struct GeneratedSong: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let color: Color
}

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

enum MockData {
    static let featuredTrack = Track(
        title: "夜に駆ける",
        artist: "YOASOBI",
        color: .indigo
    )

    static let tracks: [Track] = [
        featuredTrack,
        Track(title: "怪獣の花唄", artist: "Vaundy", color: .orange),
        Track(title: "Subtitle", artist: "Official髭男dism", color: .teal),
        Track(title: "愛が一層メロウ", artist: "離婚伝説", color: .pink),
        Track(title: "KICK BACK", artist: "米津玄師", color: .red),
        Track(title: "ナハトムジーク", artist: "Mrs. GREEN APPLE", color: .green),
        Track(title: "Shinunoga E-Wa", artist: "藤井 風", color: .purple)
    ]

    static let encounters: [Encounter] = [
        Encounter(userName: "Airi", track: tracks[1], relativeTime: "3分前", lyric: "人波の向こうで光ったメロディ"),
        Encounter(userName: "Kaito", track: tracks[2], relativeTime: "15分前", lyric: "信号待ちで揺れたイヤホン"),
        Encounter(userName: "Mina", track: tracks[3], relativeTime: "1時間前", lyric: "街角に溶ける甘いノイズ"),
        Encounter(userName: "Ren", track: tracks[4], relativeTime: "昨日", lyric: "足音と低音が重なった"),
        Encounter(userName: "Suzu", track: tracks[5], relativeTime: "昨日", lyric: "夕焼けがドラムみたいに跳ねる")
    ]

    static let generatedSongs: [GeneratedSong] = [
        GeneratedSong(title: "夜明けの詩", subtitle: "4人で作成・3/15", color: .purple),
        GeneratedSong(title: "街角の記憶", subtitle: "5人で作成・3/14", color: .blue),
        GeneratedSong(title: "Transit Echo", subtitle: "6人で作成・3/13", color: .mint)
    ]

    static let home = HomeScreenState(
        userName: "Miyu",
        featuredTrack: featuredTrack,
        weeklyTracks: tracks,
        recentEncounters: encounters,
        todayEncounterCount: 12,
        weekEncounterCount: 47,
        isOffline: false
    )

    static let recentSearches: [Track] = Array(tracks.prefix(2))
    static let popularTracks: [Track] = Array(tracks.dropFirst().prefix(3))
}
