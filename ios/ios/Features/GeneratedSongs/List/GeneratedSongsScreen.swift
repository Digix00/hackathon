import SwiftUI

struct GeneratedSongsView: View {
    @StateObject private var viewModel = GeneratedSongsViewModel()
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator

    var body: some View {
        AppScaffold(
            title: "生成曲",
            subtitle: viewModel.subtitleText,
            trailingSymbol: "plus.app"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.songs.isEmpty {
                    emptyState
                } else {
                    songsList
                }

                footerActions
            }
        }
        .task {
            viewModel.loadIfNeeded()
        }
    }

    private var songsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.songs) { song in
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
                .onAppear {
                    viewModel.loadMoreIfNeeded(currentSong: song)
                }
            }

            if viewModel.isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading {
                ProgressView("読み込み中")
            } else {
                Text(viewModel.errorMessage ?? "生成された曲がまだありません")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }

            if viewModel.errorMessage != nil {
                SecondaryButton(title: "再読み込み", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 24)
    }

    private var footerActions: some View {
        VStack(spacing: 16) {
            NavigationLink {
                NotificationListView()
            } label: {
                SecondaryButtonLabel(title: "生成完了通知を見る", systemImage: "bell.badge")
            }
            .buttonStyle(.plain)

            if let chainId = bleCoordinator.latestLyricChain?.id {
                NavigationLink {
                    ChainProgressView(chainId: chainId)
                } label: {
                    SecondaryButtonLabel(title: "生成状態を見る", systemImage: "sparkles.rectangle.stack")
                }
                .buttonStyle(.plain)
            } else {
                SecondaryButton(title: "生成状態を見る", systemImage: "sparkles.rectangle.stack") {}
                    .disabled(true)
                    .opacity(0.6)
            }
        }
        .padding(.top, 8)
    }
}
