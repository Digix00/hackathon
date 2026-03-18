import Combine
import SwiftUI

@MainActor
final class OtherUserProfileViewModel: ObservableObject {
    @Published private(set) var user: BackendPublicUser?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var actionMessage: String?
    @Published private(set) var actionErrorMessage: String?
    @Published private(set) var isMuting = false
    @Published private(set) var isBlocking = false

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
        actionMessage = nil
        actionErrorMessage = nil
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
        actionMessage = nil
        actionErrorMessage = nil
        user = nil
        do {
            user = try await client.getUser(id: userID)
        } catch {
            errorMessage = "ユーザー情報の取得に失敗しました"
        }
        isLoading = false
    }

    func mute() {
        guard let user else {
            actionErrorMessage = "ユーザー情報を読み込んでください"
            actionMessage = nil
            return
        }
        guard !isMuting else { return }
        Task { await performMute(userID: user.id) }
    }

    func block() {
        guard let user else {
            actionErrorMessage = "ユーザー情報を読み込んでください"
            actionMessage = nil
            return
        }
        guard !isBlocking else { return }
        Task { await performBlock(userID: user.id) }
    }

    private func performMute(userID: String) async {
        isMuting = true
        actionMessage = nil
        actionErrorMessage = nil
        do {
            _ = try await client.createMute(targetUserId: userID)
            actionMessage = "ミュートしました"
        } catch {
            actionErrorMessage = "ミュートに失敗しました"
        }
        isMuting = false
    }

    private func performBlock(userID: String) async {
        isBlocking = true
        actionMessage = nil
        actionErrorMessage = nil
        do {
            _ = try await client.createBlock(blockedUserId: userID)
            actionMessage = "ブロックしました"
        } catch {
            actionErrorMessage = "ブロックに失敗しました"
        }
        isBlocking = false
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
