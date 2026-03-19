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
}
