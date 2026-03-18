import Combine
import Foundation

@MainActor
final class DeleteAccountViewModel: ObservableObject {
    @Published private(set) var isDeleting = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didDelete = false

    private let client: BackendAPIClient

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
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
        } catch {
            errorMessage = "アカウント削除に失敗しました"
        }
        isDeleting = false
    }
}
