import Combine
import SwiftUI

struct PlaylistsView: View {
    @StateObject private var viewModel = PlaylistsViewModel()
    @StateObject private var myTracksViewModel = MyTracksViewModel()
    @StateObject private var favoritePlaylistsViewModel = FavoritePlaylistsViewModel()
    @StateObject private var favoriteTracksViewModel = FavoriteTracksViewModel()
    @State private var isCreatePresented = false
    @State private var isAddTrackPresented = false

    var body: some View {
        AppScaffold(
            title: "プレイリスト",
            subtitle: viewModel.subtitleText
        ) {
            VStack(alignment: .leading, spacing: 24) {
                PrimaryButton(title: viewModel.isCreating ? "作成中..." : "新しいプレイリストを作成") {
                    isCreatePresented = true
                }
                .disabled(viewModel.isCreating)

                SectionCard(title: "マイトラック") {
                    VStack(alignment: .leading, spacing: 16) {
                        SecondaryButton(
                            title: "マイトラックに追加",
                            systemImage: "plus.circle"
                        ) {
                            isAddTrackPresented = true
                        }

                        if myTracksViewModel.isLoading && myTracksViewModel.tracks.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if myTracksViewModel.tracks.isEmpty {
                            Text("まだマイトラックがありません")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        } else {
                            ForEach(myTracksViewModel.tracks) { track in
                                MyTrackRow(track: track) {
                                    if let backendId = track.backendId {
                                        myTracksViewModel.remove(trackId: backendId)
                                    }
                                }
                            }
                        }

                        if let errorMessage = myTracksViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }
                    }
                }

                SectionCard(title: "お気に入りトラック") {
                    VStack(alignment: .leading, spacing: 16) {
                        if favoriteTracksViewModel.isLoading && favoriteTracksViewModel.tracks.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if favoriteTracksViewModel.tracks.isEmpty {
                            Text("お気に入りトラックがありません")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        } else {
                            ForEach(favoriteTracksViewModel.tracks) { track in
                                MyTrackRow(track: track) {
                                    if let backendId = track.backendId {
                                        favoriteTracksViewModel.removeFavorite(trackId: backendId)
                                    }
                                }
                            }
                        }

                        if let errorMessage = favoriteTracksViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }
                    }
                }

                SectionCard(title: "お気に入りプレイリスト") {
                    VStack(alignment: .leading, spacing: 16) {
                        if favoritePlaylistsViewModel.isLoading && favoritePlaylistsViewModel.playlists.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if favoritePlaylistsViewModel.playlists.isEmpty {
                            Text("お気に入りプレイリストがありません")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        } else {
                            ForEach(favoritePlaylistsViewModel.playlists) { playlist in
                                HStack(spacing: 12) {
                                    NavigationLink {
                                        PlaylistDetailView(playlistId: playlist.id)
                                    } label: {
                                        PlaylistRowView(playlist: playlist)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        favoritePlaylistsViewModel.removeFavorite(id: playlist.id)
                                    } label: {
                                        Image(systemName: "heart.slash.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(PrototypeTheme.error)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(favoritePlaylistsViewModel.isUpdating)
                                }
                            }
                        }

                        if let errorMessage = favoritePlaylistsViewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }
                    }
                }

                SectionCard(title: "プレイリスト一覧") {
                    VStack(alignment: .leading, spacing: 16) {
                        if viewModel.isLoading && viewModel.playlists.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
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

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }
                    }
                }

                SecondaryButton(title: "更新", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                    myTracksViewModel.refresh()
                    favoritePlaylistsViewModel.refresh()
                    favoriteTracksViewModel.refresh()
                }
            }
        }
        .onAppear {
            viewModel.refresh()
            myTracksViewModel.refresh()
            favoritePlaylistsViewModel.refresh()
            favoriteTracksViewModel.refresh()
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
        .sheet(isPresented: $isAddTrackPresented) {
            SearchView(mode: .addToMyTracks) {
                myTracksViewModel.refresh()
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

private struct MyTrackRow: View {
    let track: Track
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            MockArtworkView(color: track.color, symbol: "music.note", size: 52, artwork: track.artwork)
                .shadow(color: track.color.opacity(0.2), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                Text(track.artist)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(PrototypeTheme.error)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
