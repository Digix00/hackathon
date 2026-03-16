import SwiftUI

struct OtherUserProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Capsule()
                    .fill(PrototypeTheme.border)
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(PrototypeTheme.surfaceElevated)
                            .frame(width: 100, height: 100)
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(PrototypeTheme.textTertiary)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Airi")
                            .font(.system(size: 28, weight: .black))
                        
                        Text("夜の散歩とシティポップが好き")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                SectionCard(title: "いまシェアしている曲") {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("現在のシェア曲", systemImage: "music.note")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(PrototypeTheme.accent)
                        
                        TrackSelectionRow(track: MockData.previewSharedTrack)
                    }
                }

                HStack(spacing: 16) {
                    SecondaryButton(title: "ミュート", systemImage: "speaker.slash.fill") {}
                    SecondaryButton(title: "通報", systemImage: "flag.fill") {}
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .background(PrototypeTheme.background)
        }
        .presentationDetents([.medium, .large])
    }
}

