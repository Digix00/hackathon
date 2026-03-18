import SwiftUI

struct PlaylistsView: View {
    @StateObject private var viewModel = PlaylistsViewModel()
    @State private var isCreatePresented = false

    var body: some View {
        AppScaffold(
            title: "プレイリスト",
            subtitle: viewModel.subtitleText,
            trailingSymbol: "plus.app"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                PrimaryButton(title: viewModel.isCreating ? "作成中..." : "新しいプレイリストを作成") {
                    isCreatePresented = true
                }
                .disabled(viewModel.isCreating)

                SectionCard(title: "プレイリスト一覧") {
                    VStack(alignment: .leading, spacing: 16) {
                        if viewModel.isLoading && viewModel.playlists.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if let errorMessage = viewModel.errorMessage, viewModel.playlists.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        } else if viewModel.playlists.isEmpty {
                            Text("まだプレイリストがありません")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        } else {
                            ForEach(viewModel.playlists) { playlist in
                                NavigationLink {
                                    PlaylistDetailView(playlistId: playlist.id)
                                } label: {
                                    PlaylistRowView(playlist: playlist)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                SecondaryButton(title: "更新", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .sheet(isPresented: $isCreatePresented) {
            PlaylistEditorSheet(
                title: "プレイリスト作成",
                confirmLabel: "作成",
                initialName: "",
                initialDescription: "",
                initialIsPublic: true,
                isSaving: viewModel.isCreating
            ) { name, description, isPublic in
                viewModel.createPlaylist(name: name, description: description, isPublic: isPublic)
            }
        }
    }
}

private struct PlaylistRowView: View {
    let playlist: PlaylistsViewModel.PlaylistRowModel

    var body: some View {
        HStack(spacing: 16) {
            MockArtworkView(color: playlist.accentColor, symbol: "music.note.list", size: 52)
                .shadow(color: playlist.accentColor.opacity(0.2), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                if !playlist.description.isEmpty {
                    Text(playlist.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .lineLimit(2)
                }

                Text(playlist.isPublic ? "公開" : "非公開")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(playlist.isPublic ? PrototypeTheme.success : PrototypeTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(PrototypeTheme.surfaceMuted)
                    .clipShape(Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(PrototypeTheme.textTertiary)
        }
        .padding(16)
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
