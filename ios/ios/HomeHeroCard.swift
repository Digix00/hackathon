import SwiftUI

struct FeaturedTrackHeroCard: View {
    let track: Track?
    let motionX: CGFloat
    let motionY: CGFloat

    @State private var isAnimating = false
    @Environment(\.heroNamespace) private var heroNamespace

    var body: some View {
        VStack(spacing: 48) {
            if let track {
                VStack(spacing: 40) {
                    ZStack {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(track.color.opacity(0.2), lineWidth: 1.5)
                                .frame(width: 240, height: 240)
                                .scaleEffect(isAnimating ? 1.8 : 1.0)
                                .opacity(isAnimating ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 4)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 1.3),
                                    value: isAnimating
                                )
                        }

                        MockArtworkView(color: track.color, symbol: "music.note", size: 240)
                            .shadow(color: track.color.opacity(0.2), radius: 30, x: 0, y: 15)
                            .offset(x: motionX, y: motionY)
                            .matchedGeometryEffect(id: "hero_artwork_\(track.id)", in: heroNamespace)
                    }
                    .onAppear {
                        isAnimating = true
                    }

                    VStack(spacing: 12) {
                        Text("いまシェア中")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(track.color.opacity(0.7))
                            .kerning(1.5)

                        Text(track.title)
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .tracking(-1.0)
                            .matchedGeometryEffect(id: "hero_title_\(track.id)", in: heroNamespace)

                        Text(track.artist)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .matchedGeometryEffect(id: "hero_artist_\(track.id)", in: heroNamespace)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.horizontal, 12)
                }
            } else {
                VStack(spacing: 32) {
                    Circle()
                        .fill(PrototypeTheme.surfaceMuted)
                        .frame(width: 140, height: 140)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                        .offset(x: motionX, y: motionY)

                    Text("曲を設定")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .kerning(1.2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
