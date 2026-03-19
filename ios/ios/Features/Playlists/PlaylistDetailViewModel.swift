import Combine
import SwiftUI

@MainActor
final class PlaylistDetailViewModel: ObservableObject {
    struct PlaylistDetailModel: Equatable {
        let id: String
        let name: String
        let description: String
        let isPublic: Bool
        let tracks: [PlaylistTrackRowModel]
        let createdAt: Date?
        let updatedAt: Date?
        let accentColor: Color
    }

    struct PlaylistTrackRowModel: Identifiable, Equatable {
        let id: String
        let trackId: String
        let title: String
        let artistName: String
        let artworkURL: String?
        let sortOrder: Int
        let accentColor: Color
    }

    @Published private(set) var playlist: PlaylistDetailModel?
    @Published private(set) var isLoading = false
    @Published private(set) var isUpdating = false
    @Published private(set) var isFavorite = false
    @Published private(set) var isFavoriteProcessing = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient
    private let playlistId: String
    private var hasLoaded = false
    private var hasLoadedFavoriteState = false

    init(playlistId: String, client: BackendAPIClient = BackendAPIClient()) {
        self.playlistId = playlistId
        self.client = client
    }

    func loadIfNeeded() {
        guard !hasLoaded, !isLoading else { return }
        Task { await loadPlaylist() }
    }

    func refresh() {
        hasLoadedFavoriteState = false
        Task { await loadPlaylist() }
    }

    func updatePlaylist(name: String, description: String, isPublic: Bool) {
        guard !isUpdating else { return }
        isUpdating = true
        errorMessage = nil
        Task { await updatePlaylistTask(name: name, description: description, isPublic: isPublic) }
    }

    func deletePlaylist() async -> Bool {
        errorMessage = nil
        do {
            try await client.deletePlaylist(id: playlistId)
            return true
        } catch {
            errorMessage = "プレイリストの削除に失敗しました"
            return false
        }
    }

    func addTrack(trackId: String) {
        guard !isUpdating else { return }
        isUpdating = true
        errorMessage = nil
        Task { await addTrackTask(trackId: trackId) }
    }

    func removeTrack(trackId: String) {
        guard !isUpdating else { return }
        isUpdating = true
        errorMessage = nil
        Task { await removeTrackTask(trackId: trackId) }
    }

    func toggleFavorite() {
        guard !isFavoriteProcessing else { return }
        isFavoriteProcessing = true
        errorMessage = nil
        Task { await toggleFavoriteTask() }
    }

    private func loadPlaylist() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        do {
            let playlist = try await client.getPlaylist(id: playlistId)
            self.playlist = Self.mapPlaylist(playlist)
            hasLoaded = true
            if !hasLoadedFavoriteState {
                await loadFavoriteState()
            }
        } catch {
            errorMessage = "プレイリストの取得に失敗しました"
            hasLoaded = false
        }
        isLoading = false
    }

    private func updatePlaylistTask(name: String, description: String, isPublic: Bool) async {
        defer { isUpdating = false }
        do {
            let request = UpdatePlaylistRequest(
                name: name,
                description: description,
                isPublic: isPublic
            )
            let playlist = try await client.updatePlaylist(id: playlistId, request: request)
            self.playlist = Self.mapPlaylist(playlist)
        } catch {
            errorMessage = "プレイリストの更新に失敗しました"
        }
    }

    private func addTrackTask(trackId: String) async {
        defer { isUpdating = false }
        do {
            try await client.addPlaylistTrack(id: playlistId, trackId: trackId)
            await loadPlaylist()
        } catch {
            errorMessage = "トラックの追加に失敗しました"
        }
    }

    private func removeTrackTask(trackId: String) async {
        defer { isUpdating = false }
        do {
            try await client.removePlaylistTrack(id: playlistId, trackId: trackId)
            await loadPlaylist()
        } catch {
            errorMessage = "トラックの削除に失敗しました"
        }
    }

    private func toggleFavoriteTask() async {
        defer { isFavoriteProcessing = false }
        do {
            if isFavorite {
                try await client.removePlaylistFavorite(id: playlistId)
                isFavorite = false
            } else {
                try await client.addPlaylistFavorite(id: playlistId)
                isFavorite = true
            }
        } catch let error as BackendAPIClient.BackendError {
            switch error {
            case .unexpectedStatus(let code, _) where code == 409:
                isFavorite = true
                return
            case .unexpectedStatus(let code, _) where code == 404:
                isFavorite = false
                return
            default:
                errorMessage = "お気に入りの更新に失敗しました"
            }
        } catch {
            errorMessage = "お気に入りの更新に失敗しました"
        }
    }

    private func loadFavoriteState() async {
        do {
            let isFavorite = try await isPlaylistFavorite()
            self.isFavorite = isFavorite
            hasLoadedFavoriteState = true
        } catch {
            // Favorite state is optional; keep silent.
        }
    }

    private func isPlaylistFavorite() async throws -> Bool {
        var cursor: String?
        while true {
            let response = try await client.listPlaylistFavorites(limit: 50, cursor: cursor)
            if let playlists = response.playlists, playlists.contains(where: { $0.id == playlistId }) {
                return true
            }
            guard response.pagination?.hasMore == true, let next = response.pagination?.nextCursor else {
                break
            }
            cursor = next
        }
        return false
    }

    private static func mapPlaylist(_ playlist: BackendPlaylist) -> PlaylistDetailModel {
        PlaylistDetailModel(
            id: playlist.id,
            name: playlist.name,
            description: playlist.description ?? "",
            isPublic: playlist.isPublic,
            tracks: playlist.tracks.map(mapTrack),
            createdAt: playlist.createdAt,
            updatedAt: playlist.updatedAt,
            accentColor: paletteColor(for: playlist.id)
        )
    }

    private static func mapTrack(_ track: BackendPlaylistTrack) -> PlaylistTrackRowModel {
        PlaylistTrackRowModel(
            id: track.id,
            trackId: track.trackId,
            title: track.title,
            artistName: track.artistName,
            artworkURL: track.artworkURL,
            sortOrder: track.sortOrder,
            accentColor: paletteColor(for: track.trackId)
        )
    }

    private static func paletteColor(for key: String) -> Color {
        let palette: [Color] = [.indigo, .orange, .teal, .pink, .red, .green, .purple, .blue, .mint]
        let index = Int(UInt(bitPattern: key.hashValue) % UInt(palette.count))
        return palette[index]
    }
}
