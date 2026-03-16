import SwiftUI

struct DeleteAccountView: View {
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

                Button(action: {}) {
                    Text("アカウントを削除")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(PrototypeTheme.error)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }
}
