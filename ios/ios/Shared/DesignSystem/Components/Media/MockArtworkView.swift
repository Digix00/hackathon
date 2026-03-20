import SwiftUI

struct MockArtworkView: View {
    let color: Color
    let symbol: String
    let size: CGFloat
    let artwork: String?

    // Shadow configuration
    let shadowColor: Color?
    let shadowRadius: CGFloat
    let shadowOffset: CGPoint

    init(
        color: Color,
        symbol: String,
        size: CGFloat = 56,
        artwork: String? = nil,
        shadowColor: Color? = nil,
        shadowRadius: CGFloat = 0,
        shadowX: CGFloat = 0,
        shadowY: CGFloat = 0
    ) {
        self.color = color
        self.symbol = symbol
        self.size = size
        self.artwork = artwork
        self.shadowColor = shadowColor
        self.shadowRadius = shadowRadius
        self.shadowOffset = CGPoint(x: shadowX, y: shadowY)
    }

    @ViewBuilder
    var body: some View {
        if let shadowColor, shadowRadius > 0 {
            content
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    x: shadowOffset.x,
                    y: shadowOffset.y
                )
                .compositingGroup()
        } else {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if let artworkURLString = artwork, let artworkURL = URL(string: artworkURLString) {
            AsyncImage(url: artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                default:
                    fallbackView
                }
            }
            .frame(width: size, height: size)
        } else {
            fallbackView
        }
    }

    private var fallbackView: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.95), color.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: size * 0.28, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.9))
            }
    }
}
