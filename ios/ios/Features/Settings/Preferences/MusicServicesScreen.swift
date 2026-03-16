import SwiftUI

struct MusicServicesView: View {
    var body: some View {
        AppScaffold(
            title: "音楽サービス連携",
            subtitle: "接続中のサービス"
        ) {
            SectionCard {
                VStack(spacing: 16) {
                    SettingRow(icon: "music.note.list", title: "Spotify", subtitle: "接続済み")
                    Divider()
                    SettingRow(icon: "music.note.house", title: "Apple Music", subtitle: "未接続")
                }
            }
        }
    }
}

