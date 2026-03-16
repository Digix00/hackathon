import SwiftUI

struct GeneratedSongsView: View {
    var body: some View {
        AppScaffold(
            title: "生成曲",
            subtitle: "すれ違いから生まれた曲",
            trailingSymbol: "plus.app"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(MockData.generatedSongs) { song in
                    NavigationLink {
                        GeneratedSongDetailView(song: song)
                    } label: {
                        HStack(spacing: 18) {
                            MockArtworkView(color: song.color, symbol: "waveform", size: 64)
                                .shadow(color: song.color.opacity(0.2), radius: 10, x: 0, y: 5)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(song.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Text(song.subtitle)
                                    .prototypeFont(size: 13, weight: .medium, role: .data)
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(song.color)
                        }
                        .padding(16)
                        .background(PrototypeTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 16) {
                    NavigationLink {
                        GeneratedSongNotificationView()
                    } label: {
                        SecondaryButtonLabel(title: "生成完了通知を見る", systemImage: "bell.badge")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        GeneratingStateView()
                    } label: {
                        SecondaryButtonLabel(title: "生成状態を見る", systemImage: "sparkles.rectangle.stack")
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
    }
}

