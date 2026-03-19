import SwiftUI

struct HomeFeaturedTrackCard: View {
    private enum Layout {
        static let artworkSize: CGFloat = 240
        static let rippleBaseSize: CGFloat = 260
        static let rippleExpandedScale: CGFloat = 1.6
    }

    let track: Track?
    let motionX: CGFloat
    let motionY: CGFloat

    @State private var isAnimating = false
    @Environment(\.homeNamespace) private var homeNamespace

    var body: some View {
        VStack(spacing: 64) {
            if let track {
                VStack(spacing: 48) {
                    ZStack {
                        // Keep ripple and artwork in the same coordinate space
                        // without inflating the layout width on narrow devices.
                        ForEach(0..<2) { i in
                            Circle()
                                .stroke(track.color.opacity(0.12), lineWidth: 1.0)
                                .frame(width: Layout.rippleBaseSize, height: Layout.rippleBaseSize)
                                .scaleEffect(isAnimating ? Layout.rippleExpandedScale : 1.0)
                                .opacity(isAnimating ? 0 : 1)
                                .animation(
                                    .easeOut(duration: 5)
                                        .repeatForever(autoreverses: false)
                                        .delay(Double(i) * 2.5),
                                    value: isAnimating
                                )
                        }

                        MockArtworkView(
                            color: track.color,
                            symbol: "music.note",
                            size: Layout.artworkSize,
                            artwork: track.artwork,
                            shadowColor: track.color.opacity(0.28),
                            shadowRadius: 56,
                            shadowX: 0,
                            shadowY: 24
                        )
                        .matchedGeometryEffect(id: "home_artwork_\(track.id)", in: homeNamespace)
                    }
                    .frame(width: Layout.rippleBaseSize, height: Layout.rippleBaseSize)
                    .contentShape(Rectangle())
                    .offset(x: motionX, y: motionY)
                    .onAppear {
                        isAnimating = true
                    }

                    VStack(spacing: 16) {
                        Text("NOW SHARING")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(track.color.opacity(0.6))
                            .kerning(2.0)

                        Text(track.title)
                            .font(.system(size: 40, weight: .black))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .tracking(-1.2)
                            .matchedGeometryEffect(id: "home_title_\(track.id)", in: homeNamespace)

                        Text(track.artist)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .matchedGeometryEffect(id: "home_artist_\(track.id)", in: homeNamespace)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 24)
                }
            } else {
                VStack(spacing: 40) {
                    Circle()
                        .fill(PrototypeTheme.surfaceMuted)
                        .frame(width: 140, height: 140)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                        .offset(x: motionX, y: motionY)

                    Text("SET YOUR TRACK")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .kerning(1.5)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
