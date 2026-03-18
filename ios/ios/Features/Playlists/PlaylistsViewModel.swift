import SwiftUI

@MainActor
final class PlaylistsViewModel: ObservableObject {
    struct PlaylistRowModel: Identifiable, Equatable {
        let id: String
        let name: String
        let description: String
        let isPublic: Bool
        let createdAt: Date?
        let updatedAt: Date?
        let accentColor: Color
    }

    @Published private(set) var playlists: [PlaylistRowModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isCreating = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient
    private var hasLoaded = false

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    var subtitleText: String {
        if isLoading && playlists.isEmpty {
            return "読み込み中"
        }
        if playlists.isEmpty {
            return "まだプレイリストがありません"
        }
        return "全\(playlists.count)件"
    }

    func loadIfNeeded() {
        guard !hasLoaded, !isLoading else { return }
        Task { await loadPlaylists() }
    }

    func refresh() {
        Task { await loadPlaylists() }
    }

    func createPlaylist(name: String, description: String, isPublic: Bool) {
        guard !isCreating else { return }
        isCreating = true
        errorMessage = nil
        Task { await createPlaylistTask(name: name, description: description, isPublic: isPublic) }
    }

    private func loadPlaylists() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await client.getMyPlaylists()
            let mapped = response.playlists.map(Self.mapPlaylist)
            playlists = mapped.sorted(by: Self.sortByRecent)
            hasLoaded = true
        } catch {
            errorMessage = "プレイリストの取得に失敗しました"
            hasLoaded = false
        }
        isLoading = false
    }

    private func createPlaylistTask(name: String, description: String, isPublic: Bool) async {
        defer { isCreating = false }
        do {
            let request = CreatePlaylistRequest(
                name: name,
                description: description.isEmpty ? nil : description,
                isPublic: isPublic
            )
            let playlist = try await client.createPlaylist(request)
            let row = Self.mapPlaylist(playlist)
            playlists = (playlists + [row]).sorted(by: Self.sortByRecent)
        } catch {
            errorMessage = "プレイリストの作成に失敗しました"
        }
    }

    private static func mapPlaylist(_ item: BackendPlaylistSummary) -> PlaylistRowModel {
        PlaylistRowModel(
            id: item.id,
            name: item.name,
            description: item.description ?? "",
            isPublic: item.isPublic,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            accentColor: paletteColor(for: item.id)
        )
    }

    private static func mapPlaylist(_ item: BackendPlaylist) -> PlaylistRowModel {
        PlaylistRowModel(
            id: item.id,
            name: item.name,
            description: item.description ?? "",
            isPublic: item.isPublic,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            accentColor: paletteColor(for: item.id)
        )
    }

    private static func sortByRecent(lhs: PlaylistRowModel, rhs: PlaylistRowModel) -> Bool {
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
