import SwiftUI

struct ProfileEditView: View {
    var body: some View {
        AppScaffold(
            title: "プロフィール",
            subtitle: "公開される情報を管理"
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard(title: "基本情報") {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ニックネーム")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("Miyu")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ひとこと")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            Text("音楽で街の空気を集めたい")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                
                PrimaryButton(title: "保存") {}
            }
        }
    }
}

