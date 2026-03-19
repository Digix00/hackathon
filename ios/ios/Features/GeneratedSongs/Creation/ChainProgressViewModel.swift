import Combine
import SwiftUI

@MainActor
final class ChainProgressViewModel: ObservableObject {
    struct LyricEntryRowModel: Identifiable, Equatable {
        let id: String
        let content: String
        let userName: String
        let sequenceNum: Int
    }

    @Published private(set) var chain: BackendChainDetail?
    @Published private(set) var entries: [LyricEntryRowModel] = []
    @Published private(set) var song: BackendSongDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let chainId: String?
    private let client: BackendAPIClient
    private var hasLoaded = false

    init(chainId: String?, client: BackendAPIClient = BackendAPIClient()) {
        self.chainId = chainId
        self.client = client
    }

    var progressText: String {
        guard let chain else { return "" }
        return "\(chain.participantCount)/\(chain.threshold)人が参加"
    }

    var statusTitle: String {
        guard let chain else { return "歌詞チェーン" }
        if chain.status.lowercased() == "completed" {
            return "歌詞チェーンが完成しました"
        }
        return "歌詞を集めています"
    }

    func loadIfNeeded() {
        guard !hasLoaded, !isLoading else { return }
        Task { await loadChainDetail() }
    }

    func refresh() {
        Task { await loadChainDetail() }
    }

    private func loadChainDetail() async {
        guard let chainId, !chainId.isEmpty else {
            errorMessage = "まだ歌詞チェーンがありません"
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let response = try await client.getLyricChainDetail(chainId: chainId)
            chain = response.chain
            song = response.song
            entries = response.entries
                .sorted { $0.sequenceNum < $1.sequenceNum }
                .map { entry in
                    let name = entry.user.displayName.isEmpty ? "匿名" : entry.user.displayName
                    return LyricEntryRowModel(
                        id: "\(entry.sequenceNum)-\(entry.user.id)",
                        content: entry.content,
                        userName: name,
                        sequenceNum: entry.sequenceNum
                    )
                }
            hasLoaded = true
        } catch {
            errorMessage = "歌詞チェーンの取得に失敗しました"
            hasLoaded = false
        }
        isLoading = false
    }
}
