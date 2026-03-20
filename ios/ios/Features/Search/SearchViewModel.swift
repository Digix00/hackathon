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
    @Published private(set) var isFavoriteUpdating = false
    @Published private(set) var isLoadingFavorites = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var favoriteTrackIDs: Set<String> = []

    private let client: BackendAPIClient
    private var cancellables: Set<AnyCancellable> = []

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
        $query
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in self?.search() }
            .store(in: &cancellables)
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

    func loadFavoriteTracks() {
        guard !isLoadingFavorites else { return }
        Task { await fetchFavoriteTracks() }
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

    func toggleFavoriteSelectedTrack() async {
        guard let backendId = selectedTrack?.backendId, !isFavoriteUpdating else { return }
        isFavoriteUpdating = true
        errorMessage = nil

        do {
            if favoriteTrackIDs.contains(backendId) {
                try await client.removeTrackFavorite(id: backendId)
                favoriteTrackIDs.remove(backendId)
            } else {
                _ = try await client.addTrackFavorite(id: backendId)
                favoriteTrackIDs.insert(backendId)
            }
        } catch let error as BackendAPIClient.BackendError {
            switch error {
            case .unexpectedStatus(let code, _) where code == 409:
                favoriteTrackIDs.insert(backendId)
            case .unexpectedStatus(let code, _) where code == 404:
                favoriteTrackIDs.remove(backendId)
            default:
                errorMessage = "お気に入りの更新に失敗しました"
            }
        } catch {
            errorMessage = "お気に入りの更新に失敗しました"
        }

        isFavoriteUpdating = false
    }

    var isSelectedTrackFavorite: Bool {
        guard let backendId = selectedTrack?.backendId else { return false }
        return favoriteTrackIDs.contains(backendId)
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

    private func fetchFavoriteTracks() async {
        isLoadingFavorites = true
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
            favoriteTrackIDs = Set(collected.map(\.id))
        } catch {
            // Favorite state is optional; keep silent.
        }
        isLoadingFavorites = false
    }

    private func performSearch(query: String) async {
        isSearching = true
        errorMessage = nil
        do {
            let response = try await client.searchTracks(query: query, limit: 20)
            let mapped = (response.tracks ?? []).map(mapTrack)
            results = mapped  // フォールバック色で即時表示
            if results.isEmpty { selectedTrack = nil }

            // 画像から色を抽出して results を更新（バックグラウンド並列処理）
            let updated = await resolveArtworkColors(for: mapped)
            if !Task.isCancelled { results = updated }
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
            var track = mapTrack(try await client.getTrack(id: id))
            if let resolved = await ArtworkColorExtractor.shared.extractColor(from: track.artwork) {
                track = track.withColor(resolved)
            }
            if selectedTrack?.backendId == requestedId {
                selectedTrack = track
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
            if var track = try await client.getSharedTrack().flatMap(mapSharedTrack) {
                sharedTrack = track
                if selectedTrack == nil { selectedTrack = track }

                if let resolved = await ArtworkColorExtractor.shared.extractColor(from: track.artwork) {
                    track = track.withColor(resolved)
                    sharedTrack = track
                    if selectedTrack?.backendId == track.backendId { selectedTrack = track }
                }
            } else {
                sharedTrack = nil
            }
        } catch {
            errorMessage = "シェア中の曲の取得に失敗しました"
        }
        isLoadingSharedTrack = false
    }

    /// トラック配列に対して画像から色を並列抽出し、更新済み配列を返す。
    private func resolveArtworkColors(for tracks: [Track]) async -> [Track] {
        await withTaskGroup(of: (Int, Color?).self, returning: [Track].self) { group in
            for (index, track) in tracks.enumerated() {
                group.addTask {
                    let color = await ArtworkColorExtractor.shared.extractColor(from: track.artwork)
                    return (index, color)
                }
            }
            var result = tracks
            for await (index, color) in group {
                if let color {
                    result[index] = result[index].withColor(color)
                }
            }
            return result
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
