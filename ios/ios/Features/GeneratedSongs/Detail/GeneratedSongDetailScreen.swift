import SwiftUI

struct GeneratedSongDetailView: View {
    let song: GeneratedSong
    private let contributingEncounters = MockData.generatedSongContributors

    var body: some View {
        AppScaffold(
            title: song.title,
            subtitle: "4件のすれ違いから生成",
            accentColor: song.color
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard {
                    VStack(spacing: 24) {
                        MockArtworkView(color: song.color, symbol: "waveform.and.magnifyingglass", size: 180)
                            .shadow(color: song.color.opacity(0.3), radius: 40, x: 0, y: 20)
                        
                        VStack(spacing: 8) {
                            Text(song.title)
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .truncationMode(.tail)
                            
                            Text(song.subtitle)
                                .prototypeFont(size: 15, weight: .bold, role: .data)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity)
                        
                        PrimaryButton(title: "再生する", systemImage: "play.fill") {}
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                SectionCard(title: "参加した歌詞") {
                    VStack(alignment: .leading, spacing: 20) {
                        EncounterLyricsList(encounters: contributingEncounters)
                    }
                }
                
                HStack(spacing: 12) {
                    SecondaryButton(title: "共有", systemImage: "square.and.arrow.up") {}
                    SecondaryButton(title: "保存", systemImage: "folder.badge.plus") {}
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

