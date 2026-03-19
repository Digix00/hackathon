import Combine
import SwiftUI

@MainActor
final class FavoritePlaylistsViewModel: ObservableObject {
    @Published private(set) var playlists: [PlaylistsViewModel.PlaylistRowModel] = []
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

    func removeFavorite(id: String) {
        guard !isUpdating else { return }
        isUpdating = true
        errorMessage = nil
        Task { await removeFavoriteTask(id: id) }
    }

    private func loadFavorites() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        do {
            var cursor: String?
            var collected: [BackendPlaylistSummary] = []
            while true {
                let response = try await client.listPlaylistFavorites(limit: 50, cursor: cursor)
                collected.append(contentsOf: response.playlists ?? [])
                guard response.pagination?.hasMore == true, let next = response.pagination?.nextCursor else {
                    break
                }
                cursor = next
            }
            let mapped = collected.map(Self.mapPlaylist)
            playlists = mapped.sorted(by: Self.sortByRecent)
        } catch {
            errorMessage = "お気に入りプレイリストの取得に失敗しました"
        }
        isLoading = false
    }

    private func removeFavoriteTask(id: String) async {
        defer { isUpdating = false }
        do {
            try await client.removePlaylistFavorite(id: id)
            playlists.removeAll { $0.id == id }
        } catch {
            errorMessage = "お気に入りの解除に失敗しました"
        }
    }

    private static func mapPlaylist(_ item: BackendPlaylistSummary) -> PlaylistsViewModel.PlaylistRowModel {
        PlaylistsViewModel.PlaylistRowModel(
            id: item.id,
            name: item.name,
            description: item.description ?? "",
            isPublic: item.isPublic,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            accentColor: paletteColor(for: item.id)
        )
    }

    private static func sortByRecent(lhs: PlaylistsViewModel.PlaylistRowModel, rhs: PlaylistsViewModel.PlaylistRowModel) -> Bool {
        let lhsDate = lhs.updatedAt ?? lhs.createdAt ?? .distantPast
        let rhsDate = rhs.updatedAt ?? rhs.createdAt ?? .distantPast
        return lhsDate > rhsDate
    }

    private static func paletteColor(for key: String) -> Color {
        let palette: [Color] = [.indigo, .orange, .teal, .pink, .red, .green, .purple, .blue, .mint]
        let index = Int(UInt(bitPattern: key.hashValue) % UInt(palette.count))
        return palette[index]
    }
}
