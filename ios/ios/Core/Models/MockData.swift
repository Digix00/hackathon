import SwiftUI

enum MockData {
    static let featuredTrack = Track(
        title: "夜に駆ける",
        artist: "YOASOBI",
        color: .indigo,
        artwork: "YoruniKakeru"
    )

    static let tracks: [Track] = [
        featuredTrack,
        Track(title: "怪獣の花唄", artist: "Vaundy", color: .orange, artwork: "KaijuuNoHanauta"),
        Track(title: "Subtitle", artist: "Official髭男dism", color: .teal, artwork: "Subtitle"),
        Track(title: "愛が一層メロウ", artist: "離婚伝説", color: .pink),
        Track(title: "KICK BACK", artist: "米津玄師", color: .red),
        Track(title: "ナハトムジーク", artist: "Mrs. GREEN APPLE", color: .green),
        Track(title: "Shinunoga E-Wa", artist: "藤井 風", color: .purple)
    ]

    static let encounters: [Encounter] = [
        Encounter(id: "encounter-mock-1", userName: "Airi", track: tracks[1], relativeTime: "3分前", lyric: "人波の向こうで光ったメロディ"),
        Encounter(id: "encounter-mock-2", userName: "Kaito", track: tracks[2], relativeTime: "15分前", lyric: "信号待ちで揺れたイヤホン"),
        Encounter(id: "encounter-mock-3", userName: "Mina", track: tracks[3], relativeTime: "1時間前", lyric: "街角に溶ける甘いノイズ"),
        Encounter(id: "encounter-mock-4", userName: "Ren", track: tracks[4], relativeTime: "昨日", lyric: "足音と低音が重なった"),
        Encounter(id: "encounter-mock-5", userName: "Suzu", track: tracks[5], relativeTime: "昨日", lyric: "夕焼けがドラムみたいに跳ねる")
    ]

    static let encountersWithoutLyrics: [Encounter] = [
        Encounter(id: "encounter-mock-6", userName: "Hana", track: tracks[0], relativeTime: "たった今", lyric: ""),
        Encounter(id: "encounter-mock-7", userName: "Toma", track: tracks[6], relativeTime: "28分前", lyric: ""),
        Encounter(id: "encounter-mock-8", userName: "Yuna", track: tracks[2], relativeTime: "昨日", lyric: "")
    ]

    static let generatedSongs: [GeneratedSong] = [
        GeneratedSong(
            id: "generated-mock-1",
            title: "夜明けの詩",
            subtitle: "4人で作成・3/15",
            color: .purple,
            participantCount: 4,
            generatedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 15)),
            myLyric: "夜風の隙間に落ちた言葉",
            audioURL: nil,
            chainId: nil,
            isLiked: false
        ),
        GeneratedSong(
            id: "generated-mock-2",
            title: "街角の記憶",
            subtitle: "5人で作成・3/14",
            color: .blue,
            participantCount: 5,
            generatedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 14)),
            myLyric: "薄明かりに揺れた余韻",
            audioURL: nil,
            chainId: nil,
            isLiked: true
        ),
        GeneratedSong(
            id: "generated-mock-3",
            title: "Transit Echo",
            subtitle: "6人で作成・3/13",
            color: .mint,
            participantCount: 6,
            generatedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 13)),
            myLyric: "通り過ぎた音が残る",
            audioURL: nil,
            chainId: nil,
            isLiked: false
        )
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
    static let generatedSongContributors: [Encounter] = Array(encounters.prefix(4))
    static let chainContributors: [Encounter] = Array(encounters.prefix(3))
    static let previewSharedTrack: Track = tracks[1]

    static func encounters(in section: EncounterSection) -> [Encounter] {
        encounters.filter(section.includes)
    }
}
