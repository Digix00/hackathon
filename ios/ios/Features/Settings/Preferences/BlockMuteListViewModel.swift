import Combine
import SwiftUI

@MainActor
final class BlockMuteListViewModel: ObservableObject {
    struct BlockedUserRow: Identifiable, Equatable {
        let id: String
        let blockedUserId: String
        let createdAt: Date?
    }

    struct MutedUserRow: Identifiable, Equatable {
        let id: String
        let targetUserId: String
        let createdAt: Date?
    }

    @Published var blockUserID = ""
    @Published var muteUserID = ""
    @Published private(set) var blockMessage: String?
    @Published private(set) var blockErrorMessage: String?
    @Published private(set) var muteMessage: String?
    @Published private(set) var muteErrorMessage: String?
    @Published private(set) var blockListErrorMessage: String?
    @Published private(set) var muteListErrorMessage: String?
    @Published private(set) var isBlocking = false
    @Published private(set) var isUnblocking = false
    @Published private(set) var isMuting = false
    @Published private(set) var isUnmuting = false
    @Published private(set) var isLoadingBlocks = false
    @Published private(set) var isLoadingMutes = false
    @Published private(set) var blockedUsers: [BlockedUserRow] = []
    @Published private(set) var mutedUsers: [MutedUserRow] = []

    private let client: BackendAPIClient

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func refresh() {
        Task {
            await loadBlocks()
            await loadMutes()
        }
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

    func unblock(userID: String) {
        guard !isBlockActionInProgress else { return }
        isUnblocking = true
        Task { await performUnblock(userID: userID) }
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

    func unmute(userID: String) {
        guard !isMuteActionInProgress else { return }
        isUnmuting = true
        Task { await performUnmute(userID: userID) }
    }

    private func loadBlocks() async {
        if isLoadingBlocks { return }
        isLoadingBlocks = true
        blockListErrorMessage = nil
        do {
            var cursor: String?
            var collected: [BackendBlock] = []
            while true {
                let response = try await client.listBlocks(limit: 50, cursor: cursor)
                collected.append(contentsOf: response.blocks ?? [])
                guard response.pagination?.hasMore == true, let next = response.pagination?.nextCursor else {
                    break
                }
                cursor = next
            }
            blockedUsers = collected.compactMap { block in
                guard let blockedUserId = block.blockedUserId else { return nil }
                let id = block.id ?? blockedUserId
                return BlockedUserRow(
                    id: id,
                    blockedUserId: blockedUserId,
                    createdAt: block.createdAt
                )
            }
        } catch {
            blockListErrorMessage = "ブロック一覧の取得に失敗しました"
        }
        isLoadingBlocks = false
    }

    private func loadMutes() async {
        if isLoadingMutes { return }
        isLoadingMutes = true
        muteListErrorMessage = nil
        do {
            var cursor: String?
            var collected: [BackendMute] = []
            while true {
                let response = try await client.listMutes(limit: 50, cursor: cursor)
                collected.append(contentsOf: response.mutes ?? [])
                guard response.pagination?.hasMore == true, let next = response.pagination?.nextCursor else {
                    break
                }
                cursor = next
            }
            mutedUsers = collected.compactMap { mute in
                guard let targetUserId = mute.targetUserId else { return nil }
                let id = mute.id ?? targetUserId
                return MutedUserRow(
                    id: id,
                    targetUserId: targetUserId,
                    createdAt: mute.createdAt
                )
            }
        } catch {
            muteListErrorMessage = "ミュート一覧の取得に失敗しました"
        }
        isLoadingMutes = false
    }

    private func performBlock(userID: String) async {
        blockMessage = nil
        blockErrorMessage = nil
        do {
            _ = try await client.createBlock(blockedUserId: userID)
            blockMessage = "ブロックしました"
            await loadBlocks()
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
            blockedUsers.removeAll { $0.blockedUserId == userID }
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
            await loadMutes()
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
            mutedUsers.removeAll { $0.targetUserId == userID }
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
