import SwiftUI

struct OtherUserProfileCard: View {
    var body: some View {
        SectionCard {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(PrototypeTheme.surfaceElevated)
                        .frame(width: 90, height: 90)
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }

                VStack(spacing: 8) {
                    Text("Airi")
                        .font(.system(size: 24, weight: .black))
                    Text("夜の散歩とシティポップが好き")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: "ミュート", systemImage: "speaker.slash.fill") {}
                    SecondaryButton(title: "通報", systemImage: "flag.fill") {}
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}
