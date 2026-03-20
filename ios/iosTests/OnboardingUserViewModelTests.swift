import XCTest
@testable import ios

@MainActor
final class OnboardingUserViewModelTests: XCTestCase {
    func testCanAdvanceProfileTrimsWhitespace() {
        let viewModel = OnboardingUserViewModel()

        viewModel.displayName = "  "
        XCTAssertFalse(viewModel.canAdvanceProfile)

        viewModel.displayName = "  mio  "
        XCTAssertTrue(viewModel.canAdvanceProfile)
    }

    func testSubmitUserRequiresDisplayName() {
        let viewModel = OnboardingUserViewModel()
        viewModel.displayName = "   "

        viewModel.submitUser { }

        XCTAssertEqual(viewModel.errorMessage, "ニックネームを入力してください")
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func testSubmitUserCreatesProfileWithExtendedFields() async {
        let client = MockOnboardingBackendClient()
        let viewModel = OnboardingUserViewModel(client: client)
        let completion = expectation(description: "onSuccess called")
        let birthdate = Calendar.current.date(from: DateComponents(year: 1997, month: 4, day: 12)) ?? Date()

        viewModel.displayName = "mio"
        viewModel.bio = "city pop"
        viewModel.includeBirthdate = true
        viewModel.birthdate = birthdate
        viewModel.ageVisibility = .byTen
        viewModel.prefectureId = "13"
        viewModel.sex = .female

        viewModel.submitUser {
            completion.fulfill()
        }

        await fulfillment(of: [completion], timeout: 1.0)

        let createdRequest = await client.createdRequest
        XCTAssertEqual(createdRequest?.displayName, "mio")
        XCTAssertEqual(createdRequest?.bio, "city pop")
        XCTAssertEqual(createdRequest?.birthdate, "1997-04-12")
        XCTAssertEqual(createdRequest?.ageVisibility, ProfileAgeVisibility.byTen.rawValue)
        XCTAssertEqual(createdRequest?.prefectureId, "13")
        XCTAssertEqual(createdRequest?.sex, ProfileSex.female.rawValue)
    }

    func testPrefillIfPossibleLoadsExtendedProfileFields() async {
        let client = MockOnboardingBackendClient()
        await client.setUser(
            BackendUser(
                id: "user-1",
                displayName: "kai",
                avatarURL: nil,
                bio: "ambient",
                birthdate: "2000-01-02",
                ageVisibility: ProfileAgeVisibility.exact.rawValue,
                prefectureId: "27",
                sex: ProfileSex.male.rawValue,
                createdAt: nil,
                updatedAt: nil
            )
        )
        let viewModel = OnboardingUserViewModel(client: client)

        viewModel.prefillIfPossible()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(viewModel.displayName, "kai")
        XCTAssertEqual(viewModel.bio, "ambient")
        XCTAssertTrue(viewModel.includeBirthdate)
        XCTAssertEqual(viewModel.ageVisibility, .exact)
        XCTAssertEqual(viewModel.prefectureId, "27")
        XCTAssertEqual(viewModel.sex, .male)
    }
}

actor MockOnboardingBackendClient: BackendUserAPIClient {
    private(set) var createdRequest: CreateUserRequest?
    private var user: BackendUser?

    func setUser(_ user: BackendUser?) {
        self.user = user
    }

    func createUser(_ request: CreateUserRequest) async throws -> BackendUser {
        createdRequest = request
        return BackendUser(
            id: "created-user",
            displayName: request.displayName,
            avatarURL: request.avatarURL,
            bio: request.bio,
            birthdate: request.birthdate,
            ageVisibility: request.ageVisibility,
            prefectureId: request.prefectureId,
            sex: request.sex,
            createdAt: nil,
            updatedAt: nil
        )
    }

    func getMe() async throws -> BackendUser {
        if let user {
            return user
        }
        throw BackendAPIClient.BackendError.unexpectedStatus(404, nil)
    }

    func patchMe(_ request: UpdateUserRequest) async throws -> BackendUser {
        BackendUser(
            id: "patched-user",
            displayName: request.displayName ?? "patched",
            avatarURL: request.avatarURL,
            bio: request.bio,
            birthdate: request.birthdate,
            ageVisibility: request.ageVisibility,
            prefectureId: request.prefectureId,
            sex: request.sex,
            createdAt: nil,
            updatedAt: nil
        )
    }
}
