import SwiftUI

struct OtherUserProfileView: View {
    @StateObject private var viewModel = OtherUserProfileViewModel()
    @State private var userID = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Capsule()
                    .fill(PrototypeTheme.border)
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)

                SectionCard(title: "ユーザーID") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("取得したいユーザーID", text: $userID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(PrototypeTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        PrimaryButton(
                            title: viewModel.isLoading ? "読み込み中..." : "プロフィールを表示",
                            isDisabled: userID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                        ) {
                            viewModel.load(userID: userID)
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                }

                if let user = viewModel.user {
                    OtherUserProfileCard(
                        displayName: user.displayName,
                        bio: user.bio ?? "ひとこと未設定",
                        avatarURL: user.avatarURL,
                        sharedTrack: viewModel.sharedTrack,
                        onMute: {
                            viewModel.mute()
                        },
                        onBlock: {
                            viewModel.block()
                        },
                        isMuteDisabled: viewModel.isActionInProgress,
                        isBlockDisabled: viewModel.isActionInProgress
                    )

                    if let actionMessage = viewModel.actionMessage {
                        Text(actionMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PrototypeTheme.success)
                    }

                    if let actionErrorMessage = viewModel.actionErrorMessage {
                        Text(actionErrorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PrototypeTheme.error)
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("ユーザーIDを入力してプロフィールを取得してください。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .background(PrototypeTheme.background)
        }
        .presentationDetents([.medium, .large])
    }
}
