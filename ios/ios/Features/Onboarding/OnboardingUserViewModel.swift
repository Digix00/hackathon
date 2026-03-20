import Combine
import Foundation

@MainActor
final class OnboardingUserViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var bio = "" {
        didSet {
            if isPrefillingBio {
                return
            }
            bioEdited = true
        }
    }
    @Published var includeBirthdate = false
    @Published var birthdate = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    @Published var ageVisibility = ProfileAgeVisibility.hidden
    @Published var prefectureId = ""
    @Published var sex = ProfileSex.noAnswer
    @Published private(set) var isSubmitting = false
    @Published private(set) var errorMessage: String?

    let prefectures = ProfilePrefecture.all

    private let client: BackendUserAPIClient
    private var bioEdited = false
    private var isPrefillingBio = false
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(client: BackendUserAPIClient = BackendAPIClient()) {
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
        let birthdateValue = includeBirthdate ? dateFormatter.string(from: birthdate) : nil
        let ageVisibilityValue = includeBirthdate ? ageVisibility.rawValue : nil
        let bioValue = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio
        let prefectureValue = prefectureId.isEmpty ? nil : prefectureId

        do {
            let user = try await client.getMe()
            let currentBio = user.bio
            let effectiveBio = bioEdited ? bioValue : currentBio
            if user.displayName != displayName ||
                currentBio != effectiveBio ||
                user.birthdate != birthdateValue ||
                user.ageVisibility != ageVisibilityValue ||
                user.prefectureId != prefectureValue ||
                user.sex != sex.rawValue {
                let request = UpdateUserRequest(
                    displayName: displayName,
                    avatarURL: nil,
                    bio: effectiveBio,
                    birthdate: birthdateValue,
                    ageVisibility: ageVisibilityValue,
                    prefectureId: prefectureValue,
                    sex: sex.rawValue
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
                        bio: bioValue,
                        birthdate: birthdateValue,
                        ageVisibility: ageVisibilityValue,
                        prefectureId: prefectureValue,
                        sex: sex.rawValue
                    )
                    _ = try await client.createUser(request)
                    isSubmitting = false
                    onSuccess()
                } catch {
                    errorMessage = "ユーザー作成に失敗しました"
                    isSubmitting = false
                }
            case .invalidBaseURL:
                errorMessage = "API の接続先が未設定です。`Secrets.xcconfig` の `API_BASE_URL` を確認してください"
                isSubmitting = false
            case .missingAuthToken:
                errorMessage = "ログイン状態を確認してください。再度ログインしてからお試しください"
                isSubmitting = false
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
            if !bioEdited, bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                isPrefillingBio = true
                bio = user.bio ?? ""
                isPrefillingBio = false
                bioEdited = false
            }
            if let birthdateString = user.birthdate, let parsedBirthdate = dateFormatter.date(from: birthdateString) {
                includeBirthdate = true
                birthdate = parsedBirthdate
            }
            ageVisibility = ProfileAgeVisibility(rawValue: user.ageVisibility ?? "hidden") ?? .hidden
            prefectureId = user.prefectureId ?? ""
            sex = ProfileSex(rawValue: user.sex ?? "no-answer") ?? .noAnswer
        } catch {
            // Ignore prefill failures; onboarding can proceed manually.
        }
    }
}
