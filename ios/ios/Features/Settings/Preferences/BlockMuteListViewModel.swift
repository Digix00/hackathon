import Combine
import SwiftUI

@MainActor
final class BlockMuteListViewModel: ObservableObject {
    @Published var blockUserID = ""
    @Published var muteUserID = ""
    @Published private(set) var blockMessage: String?
    @Published private(set) var blockErrorMessage: String?
    @Published private(set) var muteMessage: String?
    @Published private(set) var muteErrorMessage: String?
    @Published private(set) var isBlocking = false
    @Published private(set) var isUnblocking = false
    @Published private(set) var isMuting = false
    @Published private(set) var isUnmuting = false

    private let client: BackendAPIClient

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func block() {
        let trimmed = blockUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            blockErrorMessage = "ユーザーIDを入力してください"
            blockMessage = nil
            return
        }
        guard !isBlockActionInProgress else { return }
        isBlocking = true
        Task { await performBlock(userID: trimmed) }
    }

    func unblock() {
        let trimmed = blockUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            blockErrorMessage = "ユーザーIDを入力してください"
            blockMessage = nil
            return
        }
        guard !isBlockActionInProgress else { return }
        isUnblocking = true
        Task { await performUnblock(userID: trimmed) }
    }

    func mute() {
        let trimmed = muteUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            muteErrorMessage = "ユーザーIDを入力してください"
            muteMessage = nil
            return
        }
        guard !isMuteActionInProgress else { return }
        isMuting = true
        Task { await performMute(userID: trimmed) }
    }

    func unmute() {
        let trimmed = muteUserID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            muteErrorMessage = "ユーザーIDを入力してください"
            muteMessage = nil
            return
        }
        guard !isMuteActionInProgress else { return }
        isUnmuting = true
        Task { await performUnmute(userID: trimmed) }
    }

    private func performBlock(userID: String) async {
        blockMessage = nil
        blockErrorMessage = nil
        do {
            _ = try await client.createBlock(blockedUserId: userID)
            blockMessage = "ブロックしました"
        } catch {
            blockErrorMessage = "ブロックに失敗しました"
        }
        isBlocking = false
    }

    private func performUnblock(userID: String) async {
        blockMessage = nil
        blockErrorMessage = nil
        do {
            try await client.deleteBlock(blockedUserId: userID)
            blockMessage = "ブロックを解除しました"
        } catch {
            blockErrorMessage = "ブロック解除に失敗しました"
        }
        isUnblocking = false
    }

    private func performMute(userID: String) async {
        muteMessage = nil
        muteErrorMessage = nil
        do {
            _ = try await client.createMute(targetUserId: userID)
            muteMessage = "ミュートしました"
        } catch {
            muteErrorMessage = "ミュートに失敗しました"
        }
        isMuting = false
    }

    private func performUnmute(userID: String) async {
        muteMessage = nil
        muteErrorMessage = nil
        do {
            try await client.deleteMute(targetUserId: userID)
            muteMessage = "ミュートを解除しました"
        } catch {
        muteErrorMessage = "ミュート解除に失敗しました"
        }
        isUnmuting = false
    }

    var isBlockActionInProgress: Bool {
        isBlocking || isUnblocking
    }

    var isMuteActionInProgress: Bool {
        isMuting || isUnmuting
    }
}
