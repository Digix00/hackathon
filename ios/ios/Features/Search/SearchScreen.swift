import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.heroNamespace) var heroNamespace
    @State private var query = "夜に駆ける"

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
                        Text("曲画面に戻る")
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
                    
                    Text(query)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "mic.fill")
                        .foregroundStyle(PrototypeTheme.textTertiary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(PrototypeTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)

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
                        HStack(spacing: 16) {
                            MockArtworkView(color: MockData.featuredTrack.color, symbol: "music.note", size: 52, artwork: MockData.featuredTrack.artwork)
                                .shadow(color: MockData.featuredTrack.color.opacity(0.15), radius: 8, x: 0, y: 4)
                                .matchedGeometryEffect(id: "hero_artwork_\(MockData.featuredTrack.id)", in: heroNamespace)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(MockData.featuredTrack.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                    .matchedGeometryEffect(id: "hero_title_\(MockData.featuredTrack.id)", in: heroNamespace)
                                Text(MockData.featuredTrack.artist)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .matchedGeometryEffect(id: "hero_artist_\(MockData.featuredTrack.id)", in: heroNamespace)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(PrototypeTheme.success)
                        }
                        PrimaryButton(title: "この曲をシェアする") {
                            dismiss()
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
    }
}

