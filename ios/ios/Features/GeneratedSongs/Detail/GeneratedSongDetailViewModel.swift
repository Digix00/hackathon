import Combine
import SwiftUI

@MainActor
final class GeneratedSongDetailViewModel: ObservableObject {
    struct LyricEntryRow: Identifiable, Equatable {
        let id: String
        let content: String
        let userName: String
        let sequenceNum: Int
    }

    @Published private(set) var isLiked = false
    @Published private(set) var isProcessingLike = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lyricEntries: [LyricEntryRow] = []
    @Published private(set) var isLoadingLyrics = false
    @Published private(set) var lyricsErrorMessage: String?
    @Published private(set) var durationSec: Int?
    @Published private(set) var mood: String?

    private let client: BackendAPIClient
    private let songId: String
    private let chainId: String?
    private var hasLoadedLyrics = false

    init(song: GeneratedSong, client: BackendAPIClient = BackendAPIClient()) {
        self.songId = song.id
        self.chainId = song.chainId
        self.client = client
        self.isLiked = song.isLiked
        self.durationSec = song.durationSec
        self.mood = song.mood
    }

    func toggleLike() {
        guard !isProcessingLike else { return }
        isProcessingLike = true
        errorMessage = nil

        Task {
            do {
                if isLiked {
                    try await client.unlikeSong(id: songId)
                    await MainActor.run {
                        isLiked = false
                        isProcessingLike = false
                    }
                } else {
                    try await client.likeSong(id: songId)
                    await MainActor.run {
                        isLiked = true
                        isProcessingLike = false
                    }
                }
            } catch let error as BackendAPIClient.BackendError {
                await MainActor.run {
                    handleBackendError(error)
                    isProcessingLike = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "いいねの更新に失敗しました"
                    isProcessingLike = false
                }
            }
        }
    }

    func loadLyricsIfNeeded() {
        guard !hasLoadedLyrics, !isLoadingLyrics else { return }
        if MockData.forceGeneratedSongMocks {
            applyMockLyrics()
            return
        }
        guard let chainId, !chainId.isEmpty else {
            hasLoadedLyrics = true
            return
        }
        Task { await loadLyrics() }
    }

    private func handleBackendError(_ error: BackendAPIClient.BackendError) {
        switch error {
        case .unexpectedStatus(let status, _):
            if status == 409 {
                isLiked = true
                errorMessage = nil
                return
            }
            if status == 404 {
                isLiked = false
                errorMessage = nil
                return
            }
            errorMessage = "いいねの更新に失敗しました"
        default:
            errorMessage = "いいねの更新に失敗しました"
        }
    }

    private func loadLyrics() async {
        isLoadingLyrics = true
        lyricsErrorMessage = nil

        do {
            guard let chainId else {
                isLoadingLyrics = false
                return
            }
            let response = try await client.getLyricChainDetail(chainId: chainId)
            durationSec = response.song?.durationSec ?? durationSec
            mood = response.song?.mood ?? mood
            lyricEntries = response.entries
                .sorted { $0.sequenceNum < $1.sequenceNum }
                .map { entry in
                    let name = entry.user.displayName.isEmpty ? "匿名" : entry.user.displayName
                    return LyricEntryRow(
                        id: "\(entry.sequenceNum)-\(entry.user.id)",
                        content: entry.content,
                        userName: name,
                        sequenceNum: entry.sequenceNum
                    )
                }
            hasLoadedLyrics = true
        } catch {
            applyMockLyrics()
        }

        isLoadingLyrics = false
    }

    private func applyMockLyrics() {
        guard let mock = MockData.generatedChain(id: chainId) else {
            lyricsErrorMessage = "参加した歌詞の取得に失敗しました"
            return
        }

        durationSec = mock.song?.durationSec ?? durationSec
        mood = mock.song?.mood ?? mood
        lyricEntries = mock.entries.map { entry in
            LyricEntryRow(
                id: "\(entry.sequenceNum)-\(entry.user.id)",
                content: entry.content,
                userName: entry.user.displayName.isEmpty ? "匿名" : entry.user.displayName,
                sequenceNum: entry.sequenceNum
            )
        }
        lyricsErrorMessage = "API に接続できないためモック歌詞を表示しています"
        hasLoadedLyrics = true
    }
}
