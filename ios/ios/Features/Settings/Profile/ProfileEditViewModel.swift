import Combine
import Foundation

@MainActor
final class ProfileEditViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var avatarURL = ""
    @Published var bio = ""
    @Published var birthdate = Date()
    @Published var ageVisibility = "hidden"
    @Published var prefectureId = ""
    @Published var sex = "no-answer"

    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    private let client: BackendAPIClient
    private var loadedUser: BackendUser?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

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
            avatarURL = user.avatarURL ?? ""
            bio = user.bio ?? ""
            if let birthdateStr = user.birthdate, let date = dateFormatter.date(from: birthdateStr) {
                birthdate = date
            }
            ageVisibility = user.ageVisibility ?? "hidden"
            prefectureId = user.prefectureId ?? ""
            sex = user.sex ?? "no-answer"
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
            avatarURL: avatarURL.isEmpty ? nil : avatarURL,
            bio: bio,
            birthdate: dateFormatter.string(from: birthdate),
            ageVisibility: ageVisibility,
            prefectureId: prefectureId.isEmpty ? nil : prefectureId,
            sex: sex
        )

        do {
            let updated = try await client.patchMe(request)
            loadedUser = updated
            displayName = updated.displayName
            avatarURL = updated.avatarURL ?? ""
            bio = updated.bio ?? ""
            if let birthdateStr = updated.birthdate, let date = dateFormatter.date(from: birthdateStr) {
                birthdate = date
            }
            ageVisibility = updated.ageVisibility ?? "hidden"
            prefectureId = updated.prefectureId ?? ""
            sex = updated.sex ?? "no-answer"
            successMessage = "プロフィールを保存しました"
        } catch {
            errorMessage = "プロフィールの保存に失敗しました"
        }

        isSaving = false
    }
}
