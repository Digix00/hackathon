import Combine
import Foundation

@MainActor
final class DeleteAccountViewModel: ObservableObject {
    @Published private(set) var isDeleting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didDelete = false

    private let client: BackendAPIClient
    private let onAccountDeleted: () -> Void

    init(
        client: BackendAPIClient = BackendAPIClient(),
        onAccountDeleted: @escaping () -> Void = {}
    ) {
        self.client = client
        self.onAccountDeleted = onAccountDeleted
    }

    func deleteAccount() {
        guard !isDeleting, !didDelete else { return }
        Task { await performDelete() }
    }

    private func performDelete() async {
        isDeleting = true
        errorMessage = nil
        didDelete = false
        do {
            try await client.deleteMe()
            didDelete = true
            onAccountDeleted()
        } catch {
            errorMessage = "アカウント削除に失敗しました"
        }
        isDeleting = false
    }
}
