import SwiftUI

struct GeneratedSongDetailView: View {
    let song: GeneratedSong
    @StateObject private var viewModel: GeneratedSongDetailViewModel

    init(song: GeneratedSong) {
        self.song = song
        _viewModel = StateObject(wrappedValue: GeneratedSongDetailViewModel(song: song))
    }

    private var lyricEntries: [LyricEntryList.Row] {
        if let lyric = song.myLyric, !lyric.isEmpty {
            return [
                LyricEntryList.Row(
                    id: "my-lyric",
                    content: lyric,
                    userName: "あなた",
                    sequenceNum: 1
                )
            ]
        }
        return []
    }

    var body: some View {
        AppScaffold(
            title: song.title,
            subtitle: "\(song.participantCount)件のすれ違いから生成",
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
                        if lyricEntries.isEmpty {
                            Text("まだ歌詞が登録されていません")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        } else {
                            LyricEntryList(entries: lyricEntries)
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: "共有", systemImage: "square.and.arrow.up") {}

                    SecondaryButton(
                        title: viewModel.isLiked ? "保存済み" : "保存",
                        systemImage: viewModel.isLiked ? "heart.fill" : "heart"
                    ) {
                        viewModel.toggleLike()
                    }
                    .disabled(viewModel.isProcessingLike)
                    .opacity(viewModel.isProcessingLike ? 0.6 : 1.0)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
