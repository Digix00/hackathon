import Combine
import SwiftUI

@MainActor
final class EncounterCommentsViewModel: ObservableObject {
    @Published private(set) var comments: [EncounterComment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var submitErrorMessage: String?

    private let client: BackendAPIClient
    private var loadedEncounterID: String?
    private var requestedEncounterID: String?
    private var currentUserID: String?

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func loadIfNeeded(encounterId: String) {
        if loadedEncounterID == encounterId {
            return
        }
        if requestedEncounterID == encounterId, isLoading {
            return
        }
        Task { await loadComments(encounterId: encounterId) }
    }

    func refresh(encounterId: String) {
        Task { await loadComments(encounterId: encounterId) }
    }

    func submitComment(encounterId: String, content: String) async -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        isSubmitting = true
        submitErrorMessage = nil
        defer { isSubmitting = false }

        do {
            if currentUserID == nil {
                currentUserID = await fetchCurrentUserID()
            }
            let created = try await client.createComment(encounterId: encounterId, content: trimmed)
            let mapped = Self.mapComment(created, currentUserID: currentUserID)
            comments.append(mapped)
            comments = Self.sortComments(comments)
            return true
        } catch {
            submitErrorMessage = "コメントの送信に失敗しました"
            return false
        }
    }

    func deleteComment(_ comment: EncounterComment) {
        guard let backendID = comment.backendID else { return }
        Task { await removeComment(backendID: backendID) }
    }

    private func loadComments(encounterId: String) async {
        requestedEncounterID = encounterId
        isLoading = true
        errorMessage = nil

        do {
            let response = try await client.listComments(encounterId: encounterId)
            if currentUserID == nil {
                currentUserID = await fetchCurrentUserID()
            }
            let mapped = (response.comments ?? []).map { Self.mapComment($0, currentUserID: currentUserID) }
            guard requestedEncounterID == encounterId else { return }
            comments = Self.sortComments(mapped)
            loadedEncounterID = encounterId
        } catch {
            guard requestedEncounterID == encounterId else { return }
            errorMessage = "コメントの取得に失敗しました"
            loadedEncounterID = nil
        }
        if requestedEncounterID == encounterId {
            isLoading = false
        }
    }

    private func removeComment(backendID: String) async {
        submitErrorMessage = nil
        do {
            try await client.deleteComment(id: backendID)
            comments.removeAll { $0.backendID == backendID }
        } catch {
            submitErrorMessage = "コメントの削除に失敗しました"
        }
    }

    private func fetchCurrentUserID() async -> String? {
        if let currentUserID { return currentUserID }
        do {
            let user = try await client.getMe()
            return user.id
        } catch {
            return nil
        }
    }
}

private extension EncounterCommentsViewModel {
    static func mapComment(_ comment: BackendComment, currentUserID: String?) -> EncounterComment {
        let backendID = comment.id
        let userName = comment.user?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = userName?.isEmpty == false ? userName! : "匿名"
        let content = comment.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let relative = relativeTime(from: comment.createdAt)
        let userID = comment.user?.id
        let isMine = userID != nil && userID == currentUserID

        return EncounterComment(
            id: backendID ?? UUID().uuidString,
            backendID: backendID,
            userID: userID,
            userName: resolvedName,
            content: content,
            createdAt: comment.createdAt,
            relativeTime: relative,
            isMine: isMine
        )
    }

    static func sortComments(_ comments: [EncounterComment]) -> [EncounterComment] {
        comments.sorted {
            let lhsDate = $0.createdAt ?? .distantPast
            let rhsDate = $1.createdAt ?? .distantPast
            if lhsDate == rhsDate {
                return $0.id < $1.id
            }
            return lhsDate < rhsDate
        }
    }

    static func relativeTime(from createdAt: Date?) -> String {
        guard let createdAt else {
            return "時刻不明"
        }

        let calendar = Calendar.current
        if calendar.isDateInYesterday(createdAt) {
            return "昨日"
        }
        if !calendar.isDateInToday(createdAt) {
            let now = Date()
            let startOfCreated = calendar.startOfDay(for: createdAt)
            let startOfNow = calendar.startOfDay(for: now)
            let dayDelta = calendar.dateComponents([.day], from: startOfCreated, to: startOfNow).day ?? 0
            if dayDelta > 1 {
                return "\(dayDelta)日前"
            }
            if dayDelta < 0 {
                return "近日"
            }
            return "昨日"
        }

        let now = Date()
        let interval = max(0, now.timeIntervalSince(createdAt))
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "たった今"
        }
        if minutes < 60 {
            return "\(minutes)分前"
        }

        let hours = Int(Double(minutes) / 60.0)
        return "\(hours)時間前"
    }
}
