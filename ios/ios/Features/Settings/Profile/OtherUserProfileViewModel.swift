import Combine
import SwiftUI

@MainActor
final class OtherUserProfileViewModel: ObservableObject {
    @Published private(set) var user: BackendPublicUser?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func load(userID: String) {
        let trimmed = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }
        Task { await fetch(userID: trimmed) }
    }

    func reset() {
        user = nil
        errorMessage = nil
    }

    var sharedTrack: Track? {
        guard let shared = user?.sharedTrack else { return nil }
        return Track(
            title: shared.title,
            artist: shared.artistName,
            color: paletteColor(for: shared.id),
            artwork: nil
        )
    }

    private func fetch(userID: String) async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await client.getUser(id: userID)
        } catch {
            errorMessage = "ユーザー情報の取得に失敗しました"
        }
        isLoading = false
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
