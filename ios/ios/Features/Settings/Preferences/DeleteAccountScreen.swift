import SwiftUI

struct DeleteAccountView: View {
    @StateObject private var viewModel = DeleteAccountViewModel()
    @State private var showsConfirmation = false

    var body: some View {
        AppScaffold(
            title: "アカウント削除",
            subtitle: "削除前の最終確認"
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("この操作は元に戻せません")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(PrototypeTheme.error)

                        Text("プロフィールや履歴など、すべてのデータが削除されます。")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                }

                if viewModel.didDelete {
                    Text("アカウントを削除しました")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.success)
                }

                Button(action: { showsConfirmation = true }) {
                    Text("アカウントを削除")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(PrototypeTheme.error)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(viewModel.isDeleting || viewModel.didDelete)
                .opacity(viewModel.isDeleting || viewModel.didDelete ? 0.6 : 1)
            }
        }
        .confirmationDialog(
            "アカウントを削除しますか？",
            isPresented: $showsConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                viewModel.deleteAccount()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません。")
        }
    }
}
