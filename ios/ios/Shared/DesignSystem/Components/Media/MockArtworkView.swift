import SwiftUI
import UIKit

struct MockArtworkView: View {
    let color: Color
    let symbol: String
    var size: CGFloat = 56
    // TODO: API実装後は必ずartworkをAPIから取得したURLに置き換える（現在はローカルアセット使用）
    var artwork: String? = nil

    // 画像が存在するかチェック
    private var isValidArtwork: Bool {
        guard let artwork = artwork else { return false }
        return UIImage(named: artwork) != nil
    }

    var body: some View {
        Group {
            if let artwork = artwork, isValidArtwork {
                // TODO: API実装後はURLからの画像読み込みに変更
                Image(artwork)
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
}
