import SwiftUI

struct OtherUserProfileStandaloneView: View {
    var body: some View {
        AppScaffold(
            title: "他ユーザープロフィール",
            subtitle: "相手からの見え方を確認"
        ) {
            OtherUserProfileCard()
        }
    }
}
