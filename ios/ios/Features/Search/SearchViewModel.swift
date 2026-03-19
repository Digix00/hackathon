import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [Track] = []
    @Published private(set) var selectedTrack: Track?
    @Published private(set) var sharedTrack: Track?
    @Published private(set) var isSearching = false
    @Published private(set) var isSelecting = false
    @Published private(set) var isLoadingSharedTrack = false
    @Published private(set) var isSubmitting = false
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

    func loadSharedTrack() {
        guard !isLoadingSharedTrack else { return }
        Task { await fetchSharedTrack() }
    }

    func shareSelectedTrack() async -> Bool {
        guard let backendId = selectedTrack?.backendId, !isSubmitting else { return false }
        isSubmitting = true
        errorMessage = nil
        do {
            let shared = try await client.upsertSharedTrack(trackId: backendId)
            sharedTrack = shared.flatMap(mapSharedTrack) ?? selectedTrack
            isSubmitting = false
            return true
        } catch {
            errorMessage = "シェアの更新に失敗しました"
            isSubmitting = false
            return false
        }
    }

    func clearSharedTrack() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            try await client.deleteSharedTrack()
            sharedTrack = nil
        } catch {
            errorMessage = "シェア解除に失敗しました"
        }
        isSubmitting = false
    }

    func addSelectedTrackToMyTracks() async -> Bool {
        guard let backendId = selectedTrack?.backendId, !isSubmitting else { return false }
        isSubmitting = true
        errorMessage = nil
        do {
            _ = try await client.addUserTrack(trackId: backendId)
            isSubmitting = false
            return true
        } catch {
            errorMessage = "マイトラックに追加できませんでした"
            isSubmitting = false
            return false
        }
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
        let requestedId = id
        isSelecting = true
        errorMessage = nil
        do {
            let track = try await client.getTrack(id: id)
            if selectedTrack?.backendId == requestedId {
                selectedTrack = mapTrack(track)
            }
        } catch {
            if selectedTrack?.backendId == requestedId {
                selectedTrack = fallback
                errorMessage = "楽曲情報の取得に失敗しました"
            }
        }
        isSelecting = false
    }

    private func fetchSharedTrack() async {
        isLoadingSharedTrack = true
        errorMessage = nil
        do {
            let shared = try await client.getSharedTrack()
            sharedTrack = shared.flatMap(mapSharedTrack)
            if let sharedTrack, selectedTrack == nil {
                selectedTrack = sharedTrack
            }
        } catch {
            errorMessage = "シェア中の曲の取得に失敗しました"
        }
        isLoadingSharedTrack = false
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

    private func mapSharedTrack(_ track: BackendSharedTrack) -> Track {
        let title = track.title
        let artist = track.artistName
        let seed = track.id
        return Track(
            title: title,
            artist: artist,
            color: paletteColor(for: seed),
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
