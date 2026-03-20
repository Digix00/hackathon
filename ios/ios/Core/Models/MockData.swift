import SwiftUI

enum MockData {
    struct GeneratedChainMock {
        let chain: BackendChainDetail
        let entries: [BackendChainEntryDetail]
        let song: BackendSongDetail?
    }

    // Keep generated-song flows browsable until the backend endpoints are ready.
    static let forceGeneratedSongMocks = true

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
            durationSec: 30,
            mood: "melancholic",
            myLyric: "夜風の隙間に落ちた言葉",
            audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
            chainId: "mock-chain-completed-1",
            isLiked: false
        ),
        GeneratedSong(
            id: "generated-mock-2",
            title: "街角の記憶",
            subtitle: "5人で作成・3/14",
            color: .blue,
            participantCount: 5,
            generatedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 14)),
            durationSec: 30,
            mood: "nostalgic",
            myLyric: "薄明かりに揺れた余韻",
            audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
            chainId: "mock-chain-completed-2",
            isLiked: true
        ),
        GeneratedSong(
            id: "generated-mock-3",
            title: "Transit Echo",
            subtitle: "6人で作成・3/13",
            color: .mint,
            participantCount: 6,
            generatedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 13)),
            durationSec: 30,
            mood: "upbeat",
            myLyric: "通り過ぎた音が残る",
            audioURL: nil,
            chainId: "mock-chain-generating",
            isLiked: false
        ),
        GeneratedSong(
            id: "generated-mock-4",
            title: "Blue Platform",
            subtitle: "4人で作成・3/12",
            color: .orange,
            participantCount: 4,
            generatedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 12)),
            durationSec: 45,
            mood: "dreamy",
            myLyric: "ホームに残った靴音の余白",
            audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
            chainId: "mock-chain-completed-3",
            isLiked: false
        ),
        GeneratedSong(
            id: "generated-mock-5",
            title: "Signal Bloom",
            subtitle: "4人で作成・3/11",
            color: .teal,
            participantCount: 4,
            generatedAt: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 11)),
            durationSec: 45,
            mood: "bright",
            myLyric: "改札越しに揺れた青いひかり",
            audioURL: nil,
            chainId: "mock-chain-failed",
            isLiked: true
        )
    ]

    static let playableGeneratedSongs: [GeneratedSong] = generatedSongs.filter {
        guard let audioURL = $0.audioURL else { return false }
        return !audioURL.isEmpty
    }

    static let generatedSongNotifications: [BackendNotificationItem] = [
        BackendNotificationItem(
            id: "notification-generated-1",
            encounterId: "encounter-mock-1",
            status: "song_generated",
            readAt: nil,
            createdAt: Calendar.current.date(byAdding: .minute, value: -8, to: Date())
        ),
        BackendNotificationItem(
            id: "notification-generated-2",
            encounterId: "encounter-mock-2",
            status: "song_completed",
            readAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date()),
            createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date())
        ),
        BackendNotificationItem(
            id: "notification-encounter-1",
            encounterId: "encounter-mock-3",
            status: "encounter_created",
            readAt: nil,
            createdAt: Calendar.current.date(byAdding: .minute, value: -30, to: Date())
        ),
        BackendNotificationItem(
            id: "notification-comment-1",
            encounterId: "encounter-mock-4",
            status: "comment_posted",
            readAt: nil,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        )
    ]

    static let generatedChainMocks: [String: GeneratedChainMock] = [
        "mock-chain-completed-1": GeneratedChainMock(
            chain: BackendChainDetail(
                id: "mock-chain-completed-1",
                status: "completed",
                participantCount: 4,
                threshold: 4,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
                completedAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())
            ),
            entries: [
                mockEntry(userID: "user-a", name: "Airi", content: "夜明け前の静けさの中", sequence: 1),
                mockEntry(userID: "user-me", name: "あなた", content: "夜風の隙間に落ちた言葉", sequence: 2),
                mockEntry(userID: "user-b", name: "Kaito", content: "君の声が遠くでひらく", sequence: 3),
                mockEntry(userID: "user-c", name: "Mina", content: "街のノイズが朝を連れてくる", sequence: 4)
            ],
            song: BackendSongDetail(
                id: "generated-mock-1",
                title: "夜明けの詩",
                audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
                durationSec: 30,
                mood: "melancholic"
            )
        ),
        "mock-chain-completed-2": GeneratedChainMock(
            chain: BackendChainDetail(
                id: "mock-chain-completed-2",
                status: "completed",
                participantCount: 5,
                threshold: 5,
                createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()),
                completedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())
            ),
            entries: [
                mockEntry(userID: "user-d", name: "Ren", content: "薄明かりに揺れた余韻", sequence: 1),
                mockEntry(userID: "user-e", name: "Suzu", content: "アスファルトに残るメロディ", sequence: 2),
                mockEntry(userID: "user-f", name: "Yuna", content: "角を曲がれば昨日が光る", sequence: 3),
                mockEntry(userID: "user-g", name: "Toma", content: "止まらない景色が手を振った", sequence: 4),
                mockEntry(userID: "user-h", name: "Hana", content: "街角にだけ残る温度", sequence: 5)
            ],
            song: BackendSongDetail(
                id: "generated-mock-2",
                title: "街角の記憶",
                audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
                durationSec: 30,
                mood: "nostalgic"
            )
        ),
        "mock-chain-completed-3": GeneratedChainMock(
            chain: BackendChainDetail(
                id: "mock-chain-completed-3",
                status: "completed",
                participantCount: 4,
                threshold: 4,
                createdAt: Calendar.current.date(byAdding: .day, value: -6, to: Date()),
                completedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())
            ),
            entries: [
                mockEntry(userID: "user-i", name: "Nao", content: "ホームに残った靴音の余白", sequence: 1),
                mockEntry(userID: "user-j", name: "Kai", content: "風がポケットの中で歌う", sequence: 2),
                mockEntry(userID: "user-k", name: "Mio", content: "遅延表示が夜を引き延ばす", sequence: 3),
                mockEntry(userID: "user-l", name: "Rin", content: "笑い声が高架下に反射した", sequence: 4)
            ],
            song: BackendSongDetail(
                id: "generated-mock-4",
                title: "Blue Platform",
                audioURL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
                durationSec: 45,
                mood: "dreamy"
            )
        ),
        "mock-chain-generating": GeneratedChainMock(
            chain: BackendChainDetail(
                id: "mock-chain-generating",
                status: "generating",
                participantCount: 4,
                threshold: 4,
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
                completedAt: nil
            ),
            entries: [
                mockEntry(userID: "user-m", name: "Aoi", content: "通り過ぎた音が残る", sequence: 1),
                mockEntry(userID: "user-n", name: "Kei", content: "信号の赤が少しやわらいだ", sequence: 2),
                mockEntry(userID: "user-o", name: "Luna", content: "イヤホン越しに風が笑った", sequence: 3),
                mockEntry(userID: "user-p", name: "Sora", content: "午後の影が拍を刻んでいる", sequence: 4)
            ],
            song: nil
        ),
        "mock-chain-failed": GeneratedChainMock(
            chain: BackendChainDetail(
                id: "mock-chain-failed",
                status: "failed",
                participantCount: 4,
                threshold: 4,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                completedAt: nil
            ),
            entries: [
                mockEntry(userID: "user-q", name: "Mika", content: "改札越しに揺れた青いひかり", sequence: 1),
                mockEntry(userID: "user-r", name: "Sho", content: "階段の手前でリズムが変わる", sequence: 2),
                mockEntry(userID: "user-s", name: "Nene", content: "ふいに見上げた空が近かった", sequence: 3),
                mockEntry(userID: "user-t", name: "Kou", content: "誰かの気配だけが先に走った", sequence: 4)
            ],
            song: nil
        ),
        "mock-chain-pending": GeneratedChainMock(
            chain: BackendChainDetail(
                id: "mock-chain-pending",
                status: "pending",
                participantCount: 3,
                threshold: 4,
                createdAt: Calendar.current.date(byAdding: .minute, value: -20, to: Date()),
                completedAt: nil
            ),
            entries: [
                mockEntry(userID: "user-u", name: "Miyu", content: "このホームにまだ名前はない", sequence: 1),
                mockEntry(userID: "user-v", name: "Airi", content: "終電前の風景が低く鳴る", sequence: 2),
                mockEntry(userID: "user-w", name: "Kaito", content: "白線のそばで時間が揺れた", sequence: 3)
            ],
            song: nil
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

    static func generatedChain(id: String?) -> GeneratedChainMock? {
        guard let id else { return generatedChainMocks["mock-chain-pending"] }
        return generatedChainMocks[id] ?? generatedChainMocks["mock-chain-pending"]
    }

    private static func mockEntry(
        userID: String,
        name: String,
        content: String,
        sequence: Int
    ) -> BackendChainEntryDetail {
        BackendChainEntryDetail(
            content: content,
            sequenceNum: sequence,
            user: BackendChainEntryUser(
                id: userID,
                displayName: name,
                avatarURL: nil
            )
        )
    }
}
