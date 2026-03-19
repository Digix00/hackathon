import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [Track] = []
    @Published private(set) var selectedTrack: Track?
    @Published private(set) var isSearching = false
    @Published private(set) var isSelecting = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func search() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSearching else { return }
        Task { await performSearch(query: trimmed) }
    }

    func select(track: Track) {
        selectedTrack = track
        guard let backendId = track.backendId, !isSelecting else { return }
        Task { await fetchTrackDetail(id: backendId, fallback: track) }
    }

    private func performSearch(query: String) async {
        isSearching = true
        errorMessage = nil
        do {
            let response = try await client.searchTracks(query: query, limit: 20)
            results = (response.tracks ?? []).map(mapTrack)
            if results.isEmpty {
                selectedTrack = nil
            }
        } catch {
            errorMessage = "検索に失敗しました"
        }
        isSearching = false
    }

    private func fetchTrackDetail(id: String, fallback: Track) async {
        isSelecting = true
        errorMessage = nil
        do {
            let track = try await client.getTrack(id: id)
            selectedTrack = mapTrack(track)
        } catch {
            selectedTrack = fallback
            errorMessage = "楽曲情報の取得に失敗しました"
        }
        isSelecting = false
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
