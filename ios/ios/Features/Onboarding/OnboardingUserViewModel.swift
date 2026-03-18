import Combine
import Foundation

@MainActor
final class OnboardingUserViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var bio = ""
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    var canAdvanceProfile: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func prefillIfPossible() {
        Task { await loadCurrentUserIfAvailable() }
    }

    func submitUser(onSuccess: @escaping () -> Void) {
        guard !isSubmitting else { return }
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "ニックネームを入力してください"
            return
        }

        isSubmitting = true
        errorMessage = nil

        Task { await createIfNeeded(displayName: trimmedName, onSuccess: onSuccess) }
    }

    private func createIfNeeded(displayName: String, onSuccess: @escaping () -> Void) async {
        do {
            let user = try await client.getMe()
            let currentBio = user.bio ?? ""
            let effectiveBio: String
            if bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                effectiveBio = currentBio
            } else {
                effectiveBio = bio
            }
            if user.displayName != displayName || currentBio != effectiveBio {
                let request = UpdateUserRequest(
                    displayName: displayName,
                    avatarURL: nil,
                    bio: effectiveBio,
                    birthdate: nil,
                    ageVisibility: nil,
                    prefectureId: nil,
                    sex: nil
                )
                do {
                    _ = try await client.patchMe(request)
                } catch {
                    errorMessage = "プロフィールの更新に失敗しました"
                    isSubmitting = false
                    return
                }
            }
            isSubmitting = false
            onSuccess()
        } catch let error as BackendAPIClient.BackendError {
            switch error {
            case .unexpectedStatus(let code, _) where code == 404:
                do {
                    let request = CreateUserRequest(
                        displayName: displayName,
                        avatarURL: nil,
                        bio: bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio,
                        birthdate: nil,
                        ageVisibility: nil,
                        prefectureId: nil,
                        sex: nil
                    )
                    _ = try await client.createUser(request)
                    isSubmitting = false
                    onSuccess()
                } catch {
                    errorMessage = "ユーザー作成に失敗しました"
                    isSubmitting = false
                }
            default:
                errorMessage = "接続に失敗しました。もう一度お試しください"
                isSubmitting = false
            }
        } catch {
            errorMessage = "接続に失敗しました。もう一度お試しください"
            isSubmitting = false
        }
    }

    private func loadCurrentUserIfAvailable() async {
        do {
            let user = try await client.getMe()
            if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                displayName = user.displayName
            }
            if bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                bio = user.bio ?? ""
            }
        } catch {
            // Ignore prefill failures; onboarding can proceed manually.
        }
    }
}
