import SwiftUI

struct BlockMuteListView: View {
    var body: some View {
        AppScaffold(
            title: "ブロック / ミュート",
            subtitle: "公開範囲を調整"
        ) {
            VStack(spacing: 24) {
                SectionCard(title: "ブロック") {
                    SettingRow(icon: "hand.raised.fill", title: "ren_music")
                }
                SectionCard(title: "ミュート") {
                    SettingRow(icon: "speaker.slash.fill", title: "midnight_city")
                }
            }
        }
    }
}

