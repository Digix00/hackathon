import SwiftUI
import UIKit

struct MockArtworkView: View {
    let color: Color
    let symbol: String
    let size: CGFloat
    // TODO: API実装後は必ずartworkをAPIから取得したURLに置き換える（現在はローカルアセット使用）
    let artwork: String?

    // Shadow configuration
    let shadowColor: Color?
    let shadowRadius: CGFloat
    let shadowOffset: CGPoint

    // アセット画像を1回だけ解決し、存在しない場合はフォールバックする
    private let artworkImage: UIImage?

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
        self.artworkImage = artwork.flatMap { UIImage(named: $0) }
    }

    var body: some View {
        content
            .if(shadowRadius > 0 && shadowColor != nil) { view in
                guard let shadowColor else {
                    return view
                }
                return view
                    .shadow(
                        color: shadowColor,
                        radius: shadowRadius,
                        x: shadowOffset.x,
                        y: shadowOffset.y
                    )
                    .compositingGroup()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let artworkImage {
            // TODO: API実装後はURLからの画像読み込みに変更
            Image(uiImage: artworkImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            // 画像が指定されていない、または読み込めない場合はグラデーション表示にフォールバック
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
}
