import Foundation

@MainActor
final class ProfileEditViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var bio = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    private let client: BackendAPIClient
    private var loadedUser: BackendUser?

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    var canSave: Bool {
        !isSaving && !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func loadIfNeeded() {
        guard loadedUser == nil, !isLoading else { return }
        Task { await load() }
    }

    func refresh() {
        Task { await load() }
    }

    func save() {
        guard canSave else {
            if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = "ニックネームを入力してください"
            }
            return
        }
        Task { await persistChanges() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let user = try await client.getMe()
            loadedUser = user
            displayName = user.displayName
            bio = user.bio ?? ""
        } catch {
            errorMessage = "プロフィールの取得に失敗しました"
        }
        isLoading = false
    }

    private func persistChanges() async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = UpdateUserRequest(
            displayName: trimmedName,
            avatarURL: nil,
            bio: bio,
            birthdate: nil,
            ageVisibility: nil,
            prefectureId: nil,
            sex: nil
        )

        do {
            let updated = try await client.patchMe(request)
            loadedUser = updated
            displayName = updated.displayName
            bio = updated.bio ?? ""
            successMessage = "プロフィールを保存しました"
        } catch {
            errorMessage = "プロフィールの保存に失敗しました"
        }

        isSaving = false
    }
}
