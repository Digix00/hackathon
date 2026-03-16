import SwiftUI

struct AppearanceSettingsView: View {
    var body: some View {
        AppScaffold(
            title: "外観",
            subtitle: "表示テーマの設定"
        ) {
            SectionCard {
                VStack(alignment: .leading, spacing: 20) {
                    Label("ライトテーマ", systemImage: "sun.max.fill")
                        .font(.system(size: 16, weight: .bold))
                    Label("ダークテーマ", systemImage: "moon.fill")
                        .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}

