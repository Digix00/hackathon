import Combine
import SwiftUI

@MainActor
final class GeneratedSongsViewModel: ObservableObject {
    @Published private(set) var songs: [GeneratedSong] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient
    private var hasLoaded = false
    private var nextCursor: String?
    private var hasMore = true

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    var subtitleText: String {
        if isLoading && songs.isEmpty {
            return "読み込み中"
        }
        if songs.isEmpty {
            return "生成された曲はまだありません"
        }
        return "全\(songs.count)曲"
    }

    func loadIfNeeded() {
        guard !hasLoaded, !isLoading else { return }
        Task { await loadSongs(reset: true) }
    }

    func refresh() {
        Task { await loadSongs(reset: true) }
    }

    func loadMoreIfNeeded(currentSong: GeneratedSong) {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        guard songs.last?.id == currentSong.id else { return }
        Task { await loadSongs(reset: false) }
    }

    private func loadSongs(reset: Bool) async {
        if reset {
            hasMore = true
            nextCursor = nil
        }
        if isLoading || isLoadingMore { return }
        errorMessage = nil
        if reset {
            isLoading = true
        } else {
            isLoadingMore = true
        }

        do {
            let response = try await client.listMySongs(cursor: nextCursor)
            let mapped = response.songs.map(Self.mapSong)
            if reset {
                songs = mapped.isEmpty ? MockData.generatedSongs : mapped
            } else {
                songs.append(contentsOf: mapped)
            }
            hasLoaded = true
            hasMore = !songs.elementsEqual(MockData.generatedSongs) && response.pagination.hasMore
            nextCursor = response.pagination.nextCursor
        } catch {
            songs = MockData.generatedSongs
            hasLoaded = true
            hasMore = false
            nextCursor = nil
            errorMessage = "API に接続できないためモックを表示しています"
        }

        isLoading = false
        isLoadingMore = false
    }

    private static func mapSong(_ song: BackendUserSong) -> GeneratedSong {
        let title = song.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeTitle = title?.isEmpty == false ? title! : "無題の曲"
        let participantCount = max(0, song.participantCount)
        let dateText = formattedDate(song.generatedAt)
        let subtitle = dateText.isEmpty
            ? "\(participantCount)人で作成"
            : "\(participantCount)人で作成・\(dateText)"

        return GeneratedSong(
            id: song.id,
            title: safeTitle,
            subtitle: subtitle,
            color: paletteColor(for: song.id),
            participantCount: participantCount,
            generatedAt: song.generatedAt,
            durationSec: nil,
            mood: nil,
            myLyric: song.myLyric.isEmpty ? nil : song.myLyric,
            audioURL: song.audioURL,
            chainId: song.chainId,
            isLiked: song.liked ?? false
        )
    }

    private static func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return dateFormatter.string(from: date)
    }

    private static func paletteColor(for key: String) -> Color {
        let palette: [Color] = [.indigo, .orange, .teal, .pink, .red, .green, .purple, .blue, .mint]
        let index = Int(stableHash(key) % UInt64(palette.count))
        return palette[index]
    }

    private static func stableHash(_ s: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()
}
