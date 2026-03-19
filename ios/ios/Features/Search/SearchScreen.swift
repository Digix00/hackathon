import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.homeNamespace) var homeNamespace
    @StateObject private var viewModel = SearchViewModel()
    private let defaultQuery = "夜に駆ける"

    var body: some View {
        AppScaffold(
            title: "曲を検索",
            subtitle: "シェアする曲を選ぶ"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("ホーム画面に戻る")
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
                            PrimaryButton(title: "この曲をシェアする", isDisabled: viewModel.isSelecting) {
                                dismiss()
                            }
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let fromLeadingEdge = value.startLocation.x < 32
                    let isBackSwipe = value.translation.width > 90 && abs(value.translation.height) < 80
                    if fromLeadingEdge && isBackSwipe {
                        dismiss()
                    }
                }
        )
        .onAppear {
            if viewModel.query.isEmpty {
                viewModel.query = defaultQuery
                viewModel.search()
            }
        }
    }
}
