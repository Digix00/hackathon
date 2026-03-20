import Combine
import Foundation

@MainActor
final class NotificationListViewModel: ObservableObject {
    struct NotificationRowModel: Identifiable, Equatable {
        let id: String
        let encounterId: String
        let status: String
        let createdAt: Date?
        var isRead: Bool

        var isGeneratedSongNotification: Bool {
            let lowered = status.lowercased()
            return lowered.contains("song") || lowered.contains("track") || lowered.contains("generated")
        }
    }

    @Published private(set) var notifications: [NotificationRowModel] = []
    @Published private(set) var unreadCount: Int = 0
    @Published private(set) var totalCount: Int = 0
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var processingIDs: Set<String> = []

    private let client: BackendAPIClient
    private var hasLoaded = false

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    var subtitleText: String {
        if isLoading && notifications.isEmpty {
            return "読み込み中"
        }
        if totalCount > 0 {
            return "未読\(unreadCount)件 / 全\(totalCount)件"
        }
        if unreadCount > 0 {
            return "未読\(unreadCount)件"
        }
        return "最新の通知"
    }

    func loadIfNeeded() {
        guard !hasLoaded, !isLoading else { return }
        Task { await loadNotifications() }
    }

    func refresh() {
        Task { await loadNotifications() }
    }

    func markAsRead(id: String) {
        guard !processingIDs.contains(id) else { return }
        errorMessage = nil
        processingIDs.insert(id)
        Task { await markAsReadTask(id: id) }
    }

    func deleteNotification(id: String) {
        guard !processingIDs.contains(id) else { return }
        errorMessage = nil
        processingIDs.insert(id)
        Task { await deleteNotificationTask(id: id) }
    }

    func isProcessing(id: String) -> Bool {
        processingIDs.contains(id)
    }

    private func loadNotifications() async {
        if isLoading { return }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await client.listNotifications()
            let mapped = response.notifications
                .map(Self.mapNotification)
                .sorted { (lhs, rhs) in
                    let left = lhs.createdAt ?? .distantPast
                    let right = rhs.createdAt ?? .distantPast
                    return left > right
                }
            notifications = mapped
            unreadCount = max(0, Int(response.unreadCount))
            totalCount = max(0, Int(response.total))
            hasLoaded = true
        } catch {
            errorMessage = "通知の取得に失敗しました"
            hasLoaded = false
        }
        isLoading = false
    }

    private func markAsReadTask(id: String) async {
        defer { processingIDs.remove(id) }
        do {
            try await client.markNotificationAsRead(id: id)
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                if !notifications[index].isRead {
                    notifications[index].isRead = true
                    unreadCount = max(0, unreadCount - 1)
                }
            }
        } catch {
            errorMessage = "通知の既読更新に失敗しました"
        }
    }

    private func deleteNotificationTask(id: String) async {
        defer { processingIDs.remove(id) }
        do {
            try await client.deleteNotification(id: id)
            if let index = notifications.firstIndex(where: { $0.id == id }) {
                let wasUnread = !notifications[index].isRead
                notifications.remove(at: index)
                totalCount = max(0, totalCount - 1)
                if wasUnread {
                    unreadCount = max(0, unreadCount - 1)
                }
            }
        } catch {
            errorMessage = "通知の削除に失敗しました"
        }
    }

    private static func mapNotification(_ item: BackendNotificationItem) -> NotificationRowModel {
        let isRead = !(item.readAt?.isEmpty ?? true) || item.status.lowercased() == "read"
        return NotificationRowModel(
            id: item.id,
            encounterId: item.encounterId,
            status: item.status,
            createdAt: item.createdAt,
            isRead: isRead
        )
    }

}
