import Combine
import Foundation

@MainActor
final class CurrentUserProfileViewModel: ObservableObject {
    @Published private(set) var user: BackendUser?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient
    private var hasLoaded = false

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func loadIfNeeded() {
        guard !hasLoaded, !isLoading else { return }
        Task { await load() }
    }

    func refresh() {
        Task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await client.getMe()
            hasLoaded = true
        } catch {
            errorMessage = "プロフィールの取得に失敗しました"
            hasLoaded = false
        }
        isLoading = false
    }
}
