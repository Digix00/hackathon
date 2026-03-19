import Combine
import Foundation

import Combine
import Foundation

enum ProfileSex: String, CaseIterable, Identifiable {
    case male, female, other, noAnswer = "no-answer"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .male: return "男性"
        case .female: return "女性"
        case .other: return "その他"
        case .noAnswer: return "未回答"
        }
    }
}

enum ProfileAgeVisibility: String, CaseIterable, Identifiable {
    case hidden, exact, byTen = "by-10"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .hidden: return "非公開"
        case .exact: return "公開"
        case .byTen: return "年代のみ"
        }
    }
}

struct ProfilePrefecture: Identifiable, Hashable {
    let id: String
    let name: String
}

@MainActor
final class ProfileEditViewModel: ObservableObject {
    @Published var displayName = ""
    @Published var avatarURL = ""
    @Published var bio = ""
    @Published var birthdate = Date()
    @Published var ageVisibility = ProfileAgeVisibility.hidden
    @Published var prefectureId = ""
    @Published var sex = ProfileSex.noAnswer

    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    let prefectures: [ProfilePrefecture] = [
        .init(id: "01", name: "北海道"), .init(id: "02", name: "青森県"), .init(id: "03", name: "岩手県"),
        .init(id: "04", name: "宮城県"), .init(id: "05", name: "秋田県"), .init(id: "06", name: "山形県"),
        .init(id: "07", name: "福島県"), .init(id: "08", name: "茨城県"), .init(id: "09", name: "栃木県"),
        .init(id: "10", name: "群馬県"), .init(id: "11", name: "埼玉県"), .init(id: "12", name: "千葉県"),
        .init(id: "13", name: "東京都"), .init(id: "14", name: "神奈川県"), .init(id: "15", name: "新潟県"),
        .init(id: "16", name: "富山県"), .init(id: "17", name: "石川県"), .init(id: "18", name: "福井県"),
        .init(id: "19", name: "山梨県"), .init(id: "20", name: "長野県"), .init(id: "21", name: "岐阜県"),
        .init(id: "22", name: "静岡県"), .init(id: "23", name: "愛知県"), .init(id: "24", name: "三重県"),
        .init(id: "25", name: "滋賀県"), .init(id: "26", name: "京都府"), .init(id: "27", name: "大阪府"),
        .init(id: "28", name: "兵庫県"), .init(id: "29", name: "奈良県"), .init(id: "30", name: "和歌山県"),
        .init(id: "31", name: "鳥取県"), .init(id: "32", name: "島根県"), .init(id: "33", name: "岡山県"),
        .init(id: "34", name: "広島県"), .init(id: "35", name: "山口県"), .init(id: "36", name: "徳島県"),
        .init(id: "37", name: "香川県"), .init(id: "38", name: "愛媛県"), .init(id: "39", name: "高知県"),
        .init(id: "40", name: "福岡県"), .init(id: "41", name: "佐賀県"), .init(id: "42", name: "長崎県"),
        .init(id: "43", name: "熊本県"), .init(id: "44", name: "大分県"), .init(id: "45", name: "宮崎県"),
        .init(id: "46", name: "鹿児島県"), .init(id: "47", name: "沖縄県")
    ]

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
            ageVisibility = ProfileAgeVisibility(rawValue: user.ageVisibility ?? "hidden") ?? .hidden
            prefectureId = user.prefectureId ?? ""
            sex = ProfileSex(rawValue: user.sex ?? "no-answer") ?? .noAnswer
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
            ageVisibility: ageVisibility.rawValue,
            prefectureId: prefectureId.isEmpty ? nil : prefectureId,
            sex: sex.rawValue
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
            ageVisibility = ProfileAgeVisibility(rawValue: updated.ageVisibility ?? "hidden") ?? .hidden
            prefectureId = updated.prefectureId ?? ""
            sex = ProfileSex(rawValue: updated.sex ?? "no-answer") ?? .noAnswer
            successMessage = "プロフィールを保存しました"
        } catch {
            errorMessage = "プロフィールの保存に失敗しました"
        }

        isSaving = false
    }
}
