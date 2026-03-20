import SwiftUI

enum SearchMode {
    case shareTrack
    case addToMyTracks

    var subtitle: String {
        switch self {
        case .shareTrack:
            return "シェアする曲を選ぶ"
        case .addToMyTracks:
            return "マイトラックに追加する曲を選ぶ"
        }
    }

    var actionTitle: String {
        switch self {
        case .shareTrack:
            return "この曲をシェアする"
        case .addToMyTracks:
            return "マイトラックに追加"
        }
    }

    var backButtonTitle: String {
        switch self {
        case .shareTrack:
            return "ホーム画面に戻る"
        case .addToMyTracks:
            return "閉じる"
        }
    }
}

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.homeNamespace) var homeNamespace
    @StateObject private var viewModel = SearchViewModel()
    private let defaultQuery = "夜に駆ける"
    let mode: SearchMode
    let onTrackAdded: (() -> Void)?

    init(mode: SearchMode = .shareTrack, onTrackAdded: (() -> Void)? = nil) {
        self.mode = mode
        self.onTrackAdded = onTrackAdded
    }

    var body: some View {
        AppScaffold(
            title: "曲を検索",
            subtitle: mode.subtitle
        ) {
            VStack(alignment: .leading, spacing: 32) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text(mode.backButtonTitle)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(PrototypeTheme.surface.opacity(0.92))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                    
                    TextField("曲名・アーティストで検索", text: $viewModel.query)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.search()
                        }
                    
                    Spacer()
                    
                    Image(systemName: "mic.fill")
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(PrototypeTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                }

                SectionCard(title: "検索結果") {
                    VStack(spacing: 16) {
                        if viewModel.isSearching {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else if viewModel.results.isEmpty {
                            Text("検索結果がありません。")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        } else {
                            ForEach(viewModel.results) { track in
                                Button {
                                    viewModel.select(track: track)
                                } label: {
                                    TrackSelectionRow(track: track)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                SectionCard(title: "最近検索した曲") {
                    VStack(spacing: 16) {
                        ForEach(MockData.recentSearches) { track in
                            TrackSelectionRow(track: track)
                        }
                    }
                }

                SectionCard(title: "人気の曲") {
                    VStack(spacing: 16) {
                        ForEach(MockData.popularTracks) { track in
                            TrackSelectionRow(track: track)
                        }
                    }
                }

                if mode == .shareTrack {
                    SectionCard(title: "現在シェア中の曲") {
                        VStack(alignment: .leading, spacing: 16) {
                            if viewModel.isLoadingSharedTrack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else if let sharedTrack = viewModel.sharedTrack {
                                TrackSelectionRow(track: sharedTrack, showsActionIcon: false)
                                SecondaryButton(
                                    title: viewModel.isSubmitting ? "解除中..." : "シェアを解除",
                                    systemImage: "xmark.circle"
                                ) {
                                    Task { await viewModel.clearSharedTrack() }
                                }
                                .disabled(viewModel.isSubmitting)
                            } else {
                                Text("まだシェア中の曲がありません。")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                        }
                    }
                }

                SectionCard(title: "選択中の曲") {
                    VStack(alignment: .leading, spacing: 20) {
                        if let selectedTrack = viewModel.selectedTrack {
                            HStack(spacing: 16) {
                                MockArtworkView(color: selectedTrack.color, symbol: "music.note", size: 52, artwork: selectedTrack.artwork)
                                    .shadow(color: selectedTrack.color.opacity(0.15), radius: 8, x: 0, y: 4)
                                    .matchedGeometryEffect(id: "home_artwork_\(selectedTrack.id)", in: homeNamespace)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedTrack.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(PrototypeTheme.textPrimary)
                                        .matchedGeometryEffect(id: "home_title_\(selectedTrack.id)", in: homeNamespace)
                                    Text(selectedTrack.artist)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(PrototypeTheme.textSecondary)
                                        .matchedGeometryEffect(id: "home_artist_\(selectedTrack.id)", in: homeNamespace)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(PrototypeTheme.success)
                            }
                            PrimaryButton(
                                title: viewModel.isSubmitting ? "送信中..." : mode.actionTitle,
                                isDisabled: viewModel.isSelecting || viewModel.isSubmitting || selectedTrack.backendId == nil
                            ) {
                                Task {
                                    let success: Bool
                                    switch mode {
                                    case .shareTrack:
                                        success = await viewModel.shareSelectedTrack()
                                    case .addToMyTracks:
                                        success = await viewModel.addSelectedTrackToMyTracks()
                                        if success {
                                            onTrackAdded?()
                                        }
                                    }
                                    if success {
                                        dismiss()
                                    }
                                }
                            }

                            SecondaryButton(
                                title: viewModel.isFavoriteUpdating
                                    ? "更新中..."
                                    : (viewModel.isSelectedTrackFavorite ? "お気に入り解除" : "お気に入りに追加"),
                                systemImage: viewModel.isSelectedTrackFavorite ? "heart.slash" : "heart"
                            ) {
                                Task { await viewModel.toggleFavoriteSelectedTrack() }
                            }
                            .disabled(viewModel.isFavoriteUpdating || selectedTrack.backendId == nil)
                        } else {
                            Text("曲を選択してください。")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onAppear {
            if viewModel.query.isEmpty {
                viewModel.query = defaultQuery
                viewModel.search()
            }
            viewModel.loadFavoriteTracks()
            if mode == .shareTrack {
                viewModel.loadSharedTrack()
            }
        }
        .if(mode == .shareTrack) { view in
            view.lockLibraryPageSwipe()
        }
        .if(mode == .shareTrack) { view in
            view.disableInteractivePopGesture(true)
        }
    }
}
