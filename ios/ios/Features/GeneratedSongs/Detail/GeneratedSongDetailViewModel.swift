import SwiftUI

@MainActor
final class GeneratedSongDetailViewModel: ObservableObject {
    @Published private(set) var isLiked = false
    @Published private(set) var isProcessingLike = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient
    private let songId: String

    init(song: GeneratedSong, client: BackendAPIClient = BackendAPIClient()) {
        self.songId = song.id
        self.client = client
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
                    let response = try await client.likeSong(id: songId)
                    await MainActor.run {
                        isLiked = response.liked
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
}
