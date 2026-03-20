import Foundation
import SwiftUI
import Combine

@MainActor
final class LocalCompositionStudioStore: ObservableObject {
    static let shared = LocalCompositionStudioStore()

    struct LocalChainResult {
        let chain: BackendChainDetail
        let entries: [BackendChainEntryDetail]
        let song: BackendSongDetail?
    }

    struct TemplateSeed: Identifiable, Equatable {
        let id: String
        let userName: String
        let content: String
    }

    struct Template: Identifiable, Equatable {
        let id: String
        let title: String
        let mood: String
        let summary: String
        let threshold: Int
        let palette: Palette
        let seeds: [TemplateSeed]
    }

    struct ProjectSummary: Identifiable, Equatable {
        let id: String
        let title: String
        let mood: String
        let participantCount: Int
        let threshold: Int
        let previewLyric: String
        let palette: Palette
        let isCompleted: Bool
    }

    enum Palette: String, CaseIterable, Codable {
        case indigo
        case blue
        case teal
        case orange
        case pink
        case mint

        var color: Color {
            switch self {
            case .indigo: return .indigo
            case .blue: return .blue
            case .teal: return .teal
            case .orange: return .orange
            case .pink: return .pink
            case .mint: return .mint
            }
        }
    }

    private struct PersistedEntry: Codable, Equatable {
        let id: String
        let userName: String
        let content: String
        let createdAt: Date
        let isCurrentUser: Bool
    }

    private struct PersistedProject: Codable, Equatable {
        let chainID: String
        let songID: String
        var title: String
        var mood: String
        let threshold: Int
        let palette: Palette
        let createdAt: Date
        var completedAt: Date?
        var entries: [PersistedEntry]
        var isLiked: Bool
        var audioURL: String?
        var nextDemoIndex: Int
    }

    @Published private var projects: [PersistedProject] = []

    let templates: [Template]

    private static let storageKey = "generated_song.local_composition_projects"
    private static let sampleAudioURLs = [
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"
    ]
    private static let demoNames = ["Airi", "Kaito", "Mina", "Ren", "Suzu", "Hana"]
    private static let moodLibrary: [String: [String]] = [
        "dreamy": [
            "終電の窓に浮いた雲を追いかけた",
            "ネオンの粒がゆっくりと滲んでいく",
            "眠らない街がコーラスみたいに揺れた"
        ],
        "upbeat": [
            "交差点のビートで心拍が跳ねる",
            "笑い声がリズムになって駆け抜ける",
            "改札の向こうで未来が手を振った"
        ],
        "melancholic": [
            "夜風にほどけた言葉がまだ温かい",
            "見えない拍だけがホームに残った",
            "遠ざかる灯りが静かにサビへ向かう"
        ],
        "bright": [
            "朝の光がスニーカーの先で弾けた",
            "歩幅の数だけメロディが増えていく",
            "今日の街は少しだけやさしく鳴る"
        ],
        "nostalgic": [
            "古い看板の下で昨日の匂いがした",
            "曲がり角のたびに記憶がフェードインする",
            "遠い駅名が胸の奥でリフレインした"
        ]
    ]

    private init() {
        self.templates = Self.defaultTemplates
        self.projects = Self.loadProjects()
    }

    var completedSongs: [GeneratedSong] {
        projects
            .filter { $0.completedAt != nil }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .map(makeSong(from:))
    }

    var projectSummaries: [ProjectSummary] {
        projects
            .sorted { $0.createdAt > $1.createdAt }
            .map {
                ProjectSummary(
                    id: $0.chainID,
                    title: $0.title,
                    mood: $0.mood,
                    participantCount: $0.entries.count,
                    threshold: $0.threshold,
                    previewLyric: $0.entries.last?.content ?? "",
                    palette: $0.palette,
                    isCompleted: $0.completedAt != nil
                )
            }
    }

    func createProject(title: String, mood: String, openingLyric: String) -> String {
        let chainID = "local-chain-\(UUID().uuidString)"
        let project = PersistedProject(
            chainID: chainID,
            songID: "local-song-\(UUID().uuidString)",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Resonance" : title.trimmingCharacters(in: .whitespacesAndNewlines),
            mood: mood,
            threshold: 4,
            palette: Self.defaultTemplates.randomElement()?.palette ?? .indigo,
            createdAt: Date(),
            completedAt: nil,
            entries: [
                PersistedEntry(
                    id: UUID().uuidString,
                    userName: "あなた",
                    content: openingLyric.trimmingCharacters(in: .whitespacesAndNewlines),
                    createdAt: Date(),
                    isCurrentUser: true
                )
            ],
            isLiked: false,
            audioURL: nil,
            nextDemoIndex: 0
        )
        projects.insert(project, at: 0)
        persist()
        return chainID
    }

    func createProject(from templateID: String, userLyric: String) -> String? {
        guard let template = templates.first(where: { $0.id == templateID }) else { return nil }

        let chainID = "local-chain-\(UUID().uuidString)"
        var entries = template.seeds.enumerated().map { index, seed in
            PersistedEntry(
                id: "\(template.id)-seed-\(index)",
                userName: seed.userName,
                content: seed.content,
                createdAt: Date(),
                isCurrentUser: false
            )
        }

        entries.append(
            PersistedEntry(
                id: UUID().uuidString,
                userName: "あなた",
                content: userLyric.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: Date(),
                isCurrentUser: true
            )
        )

        var project = PersistedProject(
            chainID: chainID,
            songID: "local-song-\(UUID().uuidString)",
            title: template.title,
            mood: template.mood,
            threshold: template.threshold,
            palette: template.palette,
            createdAt: Date(),
            completedAt: nil,
            entries: entries,
            isLiked: false,
            audioURL: nil,
            nextDemoIndex: template.seeds.count
        )
        completeIfNeeded(&project)
        projects.insert(project, at: 0)
        persist()
        return chainID
    }

    func appendDemoLyric(to chainID: String) {
        guard let index = projects.firstIndex(where: { $0.chainID == chainID }) else { return }
        guard projects[index].completedAt == nil else { return }
        guard projects[index].entries.count < projects[index].threshold else { return }

        let demoLines = Self.moodLibrary[projects[index].mood.lowercased()] ?? Self.moodLibrary["dreamy"] ?? []
        let nextIndex = projects[index].nextDemoIndex
        let content = demoLines[nextIndex % max(demoLines.count, 1)]
        let userName = Self.demoNames[nextIndex % Self.demoNames.count]
        projects[index].entries.append(
            PersistedEntry(
                id: UUID().uuidString,
                userName: userName,
                content: content,
                createdAt: Date(),
                isCurrentUser: false
            )
        )
        projects[index].nextDemoIndex += 1
        completeIfNeeded(&projects[index])
        persist()
    }

    func generatedChain(id: String?) -> LocalChainResult? {
        guard let id else { return nil }
        guard let project = projects.first(where: { $0.chainID == id }) else { return nil }

        let chain = BackendChainDetail(
            id: project.chainID,
            status: project.completedAt == nil ? "pending" : "completed",
            participantCount: project.entries.count,
            threshold: project.threshold,
            createdAt: project.createdAt,
            completedAt: project.completedAt
        )

        let entries = project.entries.enumerated().map { index, entry in
            BackendChainEntryDetail(
                content: entry.content,
                sequenceNum: index + 1,
                user: BackendChainEntryUser(
                    id: entry.id,
                    displayName: entry.userName,
                    avatarURL: nil
                )
            )
        }

        let song: BackendSongDetail? = project.completedAt == nil ? nil : BackendSongDetail(
            id: project.songID,
            title: project.title,
            audioURL: project.audioURL,
            durationSec: 45,
            mood: project.mood
        )

        return LocalChainResult(chain: chain, entries: entries, song: song)
    }

    func contains(chainID: String) -> Bool {
        projects.contains { $0.chainID == chainID }
    }

    func containsSong(songID: String) -> Bool {
        projects.contains { $0.songID == songID }
    }

    func toggleLike(songID: String) {
        guard let index = projects.firstIndex(where: { $0.songID == songID }) else { return }
        projects[index].isLiked.toggle()
        persist()
    }

    func isSongLiked(songID: String) -> Bool {
        projects.first(where: { $0.songID == songID })?.isLiked ?? false
    }

    private func makeSong(from project: PersistedProject) -> GeneratedSong {
        let dateText = Self.dateFormatter.string(from: project.completedAt ?? project.createdAt)
        let subtitle = "\(project.entries.count)人で作成・\(dateText)"
        let myLyric = project.entries.last(where: { $0.isCurrentUser })?.content

        return GeneratedSong(
            id: project.songID,
            title: project.title,
            subtitle: subtitle,
            color: project.palette.color,
            participantCount: project.entries.count,
            generatedAt: project.completedAt,
            durationSec: 45,
            mood: project.mood,
            myLyric: myLyric,
            audioURL: project.audioURL,
            chainId: project.chainID,
            isLiked: project.isLiked
        )
    }

    private func completeIfNeeded(_ project: inout PersistedProject) {
        guard project.completedAt == nil else { return }
        guard project.entries.count >= project.threshold else { return }

        project.completedAt = Date()
        let audioIndex = abs(project.songID.hashValue) % Self.sampleAudioURLs.count
        project.audioURL = Self.sampleAudioURLs[audioIndex]
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(projects) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
        objectWillChange.send()
    }

    private static func loadProjects() -> [PersistedProject] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PersistedProject].self, from: data)) ?? []
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static let defaultTemplates: [Template] = [
        Template(
            id: "template-station",
            title: "終電前ステーション",
            mood: "dreamy",
            summary: "3つの断片が集まった駅ホームのチェーン。最後の1行を書けば曲になります。",
            threshold: 4,
            palette: .indigo,
            seeds: [
                TemplateSeed(id: "station-1", userName: "Airi", content: "終電前のホームが青く息をしていた"),
                TemplateSeed(id: "station-2", userName: "Kaito", content: "遠くのベルだけが心拍みたいに鳴る"),
                TemplateSeed(id: "station-3", userName: "Mina", content: "誰もいないベンチに夜が座っていた")
            ]
        ),
        Template(
            id: "template-crossing",
            title: "交差点のブレス",
            mood: "upbeat",
            summary: "2つの断片から始まった都会のビート。あなたの言葉でリズムを足せます。",
            threshold: 4,
            palette: .orange,
            seeds: [
                TemplateSeed(id: "crossing-1", userName: "Ren", content: "信号が変わるたび景色まで跳ねた"),
                TemplateSeed(id: "crossing-2", userName: "Suzu", content: "スニーカーの先で朝がクラップした")
            ]
        )
    ]
}
