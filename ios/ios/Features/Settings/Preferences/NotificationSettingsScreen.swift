import SwiftUI

struct NotificationSettingsView: View {
    var body: some View {
        AppScaffold(
            title: "通知設定",
            subtitle: "受け取る通知を管理"
        ) {
            SectionCard {
                VStack(spacing: 20) {
                    Toggle(isOn: .constant(true)) {
                        Text("すれ違い通知")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Toggle(isOn: .constant(true)) {
                        Text("生成曲の通知")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
        }
    }
}

