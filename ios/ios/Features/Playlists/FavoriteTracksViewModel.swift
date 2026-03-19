import Combine
import SwiftUI

@MainActor
final class FavoriteTracksViewModel: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isUpdating = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func refresh() {
        Task { await loadFavorites() }
    }

    func removeFavorite(trackId: String) {
        guard !isUpdating else { return }
        isUpdating = true
        errorMessage = nil
        Task { await removeFavoriteTask(trackId: trackId) }
    }

    private func loadFavorites() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        do {
            var cursor: String?
            var collected: [BackendPublicTrack] = []
            while true {
                let response = try await client.listTrackFavorites(limit: 50, cursor: cursor)
                collected.append(contentsOf: response.tracks ?? [])
                guard response.pagination?.hasMore == true, let next = response.pagination?.nextCursor else {
                    break
                }
                cursor = next
            }
            tracks = collected.map(mapTrack)
        } catch {
            errorMessage = "お気に入りトラックの取得に失敗しました"
        }
        isLoading = false
    }

    private func removeFavoriteTask(trackId: String) async {
        defer { isUpdating = false }
        do {
            try await client.removeTrackFavorite(id: trackId)
            tracks.removeAll { $0.backendId == trackId }
        } catch {
            errorMessage = "お気に入りの解除に失敗しました"
        }
    }

    private func mapTrack(_ track: BackendPublicTrack) -> Track {
        Track(
            title: track.title,
            artist: track.artistName,
            color: paletteColor(for: track.id),
            artwork: track.artworkURL,
            backendId: track.id
        )
    }

    private func paletteColor(for key: String) -> Color {
        let palette: [Color] = [
            .indigo,
            .orange,
            .teal,
            .pink,
            .red,
            .green,
            .purple,
            .blue,
            .mint
        ]
        let index = Int(UInt(bitPattern: key.hashValue) % UInt(palette.count))
        return palette[index]
    }
}
