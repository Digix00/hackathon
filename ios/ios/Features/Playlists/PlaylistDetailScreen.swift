import Combine
import SwiftUI

struct PlaylistDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PlaylistDetailViewModel
    @State private var isEditPresented = false
    @State private var isAddTrackPresented = false
    @State private var isDeleteConfirmPresented = false

    init(playlistId: String) {
        _viewModel = StateObject(wrappedValue: PlaylistDetailViewModel(playlistId: playlistId))
    }

    var body: some View {
        AppScaffold(
            title: viewModel.playlist?.name ?? "プレイリスト",
            subtitle: subtitleText
        ) {
            VStack(alignment: .leading, spacing: 24) {
                if viewModel.isLoading && viewModel.playlist == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let errorMessage = viewModel.errorMessage, viewModel.playlist == nil {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                }

                if let playlist = viewModel.playlist {
                    SectionCard(title: "概要") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(playlist.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)

                            if !playlist.description.isEmpty {
                                Text(playlist.description)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }

                            HStack(spacing: 12) {
                                Label(playlist.isPublic ? "公開" : "非公開", systemImage: playlist.isPublic ? "globe.asia.australia" : "lock.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(playlist.isPublic ? PrototypeTheme.success : PrototypeTheme.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(PrototypeTheme.surfaceMuted)
                                    .clipShape(Capsule())

                                if let updated = playlist.updatedAt ?? playlist.createdAt {
                                    Text("更新: \(dateText(updated))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(PrototypeTheme.textTertiary)
                                }
                            }
                        }
                    }

                    SectionCard(title: "トラック") {
                        VStack(alignment: .leading, spacing: 16) {
                            if playlist.tracks.isEmpty {
                                Text("まだトラックがありません")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            } else {
                                ForEach(playlist.tracks) { track in
                                    PlaylistTrackRow(track: track) {
                                        viewModel.removeTrack(trackId: track.trackId)
                                    }
                                }
                            }

                            SecondaryButton(title: "トラックを追加", systemImage: "plus.circle") {
                                isAddTrackPresented = true
                            }
                        }
                    }

                    if let errorMessage = viewModel.errorMessage, viewModel.playlist != nil {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PrototypeTheme.error)
                    }

                    VStack(spacing: 12) {
                        PrimaryButton(title: viewModel.isFavorite ? "お気に入り解除" : "お気に入りに追加") {
                            viewModel.toggleFavorite()
                        }
                        .disabled(viewModel.isFavoriteProcessing)

                        SecondaryButton(title: "編集", systemImage: "pencil") {
                            isEditPresented = true
                        }

                        SecondaryButton(title: "削除", systemImage: "trash") {
                            isDeleteConfirmPresented = true
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .sheet(isPresented: $isEditPresented) {
            if let playlist = viewModel.playlist {
                PlaylistEditorSheet(
                    title: "プレイリスト編集",
                    confirmLabel: "保存",
                    initialName: playlist.name,
                    initialDescription: playlist.description,
                    initialIsPublic: playlist.isPublic,
                    isSaving: viewModel.isUpdating
                ) { name, description, isPublic in
                    viewModel.updatePlaylist(name: name, description: description, isPublic: isPublic)
                }
            }
        }
        .sheet(isPresented: $isAddTrackPresented) {
            PlaylistAddTrackSheet(isSaving: viewModel.isUpdating) { trackId in
                viewModel.addTrack(trackId: trackId)
            }
        }
        .alert("プレイリストを削除しますか？", isPresented: $isDeleteConfirmPresented) {
            Button("削除", role: .destructive) {
                Task {
                    let success = await viewModel.deletePlaylist()
                    if success {
                        dismiss()
                    }
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この操作は取り消せません")
        }
    }

    private var subtitleText: String? {
        if viewModel.isLoading {
            return "読み込み中"
        }
        if let playlist = viewModel.playlist {
            return "トラック\(playlist.tracks.count)曲"
        }
        return "プレイリスト詳細"
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

private struct PlaylistTrackRow: View {
    let track: PlaylistDetailViewModel.PlaylistTrackRowModel
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MockArtworkView(color: track.accentColor, symbol: "music.note", size: 46)
                .shadow(color: track.accentColor.opacity(0.18), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                Text(track.artistName)
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
        .padding(12)
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct PlaylistAddTrackSheet: View {
    let isSaving: Bool
    let onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var trackId: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                PlaylistTextField(title: "トラックID", placeholder: "spotify:track:...", text: $trackId)

                PrimaryButton(title: isSaving ? "追加中..." : "追加", isDisabled: trackId.isEmpty || isSaving) {
                    onSubmit(trackId)
                    dismiss()
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("トラック追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}
