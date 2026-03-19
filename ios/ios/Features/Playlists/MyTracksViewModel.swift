import Combine
import SwiftUI

@MainActor
final class MyTracksViewModel: ObservableObject {
    @Published private(set) var tracks: [Track] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isUpdating = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func refresh() {
        Task { await loadTracks() }
    }

    func remove(trackId: String) {
        guard !isUpdating else { return }
        isUpdating = true
        errorMessage = nil
        Task { await removeTrackTask(trackId: trackId) }
    }

    private func loadTracks() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await client.listUserTracks(limit: 50)
            tracks = (response.tracks ?? []).map(mapTrack)
        } catch {
            errorMessage = "マイトラックの取得に失敗しました"
        }
        isLoading = false
    }

    private func removeTrackTask(trackId: String) async {
        defer { isUpdating = false }
        do {
            try await client.deleteUserTrack(id: trackId)
            tracks.removeAll { $0.backendId == trackId }
        } catch {
            errorMessage = "マイトラックの削除に失敗しました"
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
