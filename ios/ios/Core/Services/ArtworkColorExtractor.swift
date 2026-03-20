import UIKit
import SwiftUI

/// アートワーク画像の外周ピクセルから背景色を推定し、
/// テンプレパレット10色の中から最も近い色を返すサービス。
/// NSCache で同一URLの再ダウンロードを防止する。
actor ArtworkColorExtractor {
    static let shared = ArtworkColorExtractor()

    private let cache = NSCache<NSString, UIColor>()

    /// テンプレパレット 10 色
    private let templatePalette: [UIColor] = [
        UIColor(red: 0.86, green: 0.08, blue: 0.24, alpha: 1), // crimson
        UIColor(red: 0.97, green: 0.45, blue: 0.00, alpha: 1), // orange
        UIColor(red: 0.93, green: 0.70, blue: 0.00, alpha: 1), // amber
        UIColor(red: 0.33, green: 0.75, blue: 0.09, alpha: 1), // lime
        UIColor(red: 0.06, green: 0.68, blue: 0.49, alpha: 1), // emerald
        UIColor(red: 0.02, green: 0.68, blue: 0.90, alpha: 1), // sky
        UIColor(red: 0.29, green: 0.30, blue: 0.89, alpha: 1), // indigo
        UIColor(red: 0.55, green: 0.27, blue: 0.88, alpha: 1), // violet
        UIColor(red: 0.96, green: 0.27, blue: 0.55, alpha: 1), // rose
        UIColor(red: 0.27, green: 0.39, blue: 0.54, alpha: 1), // slate
    ]

    // MARK: - Public API

    /// アートワーク URL から外周色を推定し、テンプレパレットで最近傍の色を返す。
    /// 取得失敗時は nil を返す（呼び出し元でフォールバック色を使用すること）。
    func extractColor(from urlString: String?) async -> Color? {
        guard let urlString, !urlString.isEmpty,
              let url = URL(string: urlString) else { return nil }

        if let cached = cache.object(forKey: urlString as NSString) {
            return Color(cached)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data),
                  let border = borderAverageColor(from: image) else { return nil }

            let matched = closestTemplateColor(to: border)
            cache.setObject(matched, forKey: urlString as NSString)
            return Color(matched)
        } catch {
            return nil
        }
    }

    // MARK: - Private

    /// 画像を 16×16 に縮小し、外周リング（60ピクセル）の平均 RGB を返す。
    /// アルバムアートは外縁が背景色を持つケースが多いため、外周平均が背景推定に有効。
    private func borderAverageColor(from image: UIImage) -> UIColor? {
        let side = 16

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let ctx = CGContext(
            data: nil,
            width: side, height: side,
            bitsPerComponent: 8,
            bytesPerRow: side * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        let rect = CGRect(origin: .zero, size: CGSize(width: side, height: side))
        let cgImage = image.cgImage ?? UIGraphicsImageRenderer(size: rect.size).image { _ in
            image.draw(in: rect)
        }.cgImage

        guard let cg = cgImage else { return nil }
        ctx.draw(cg, in: rect)

        guard let data = ctx.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: side * side * 4)

        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        var count: CGFloat = 0

        for row in 0..<side {
            for col in 0..<side {
                // 外周リングのみ対象（row/col が 0 または side-1）
                guard row == 0 || row == side - 1 || col == 0 || col == side - 1 else { continue }

                let idx = (row * side + col) * 4
                totalR += CGFloat(ptr[idx])     / 255.0
                totalG += CGFloat(ptr[idx + 1]) / 255.0
                totalB += CGFloat(ptr[idx + 2]) / 255.0
                count += 1
            }
        }

        guard count > 0 else { return nil }
        return UIColor(red: totalR / count, green: totalG / count, blue: totalB / count, alpha: 1)
    }

    /// RGB 空間のユークリッド距離でテンプレパレットから最近傍の色を返す。
    private func closestTemplateColor(to target: UIColor) -> UIColor {
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        target.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)

        var minDist: CGFloat = .infinity
        var closest = templatePalette[0]

        for candidate in templatePalette {
            var cr: CGFloat = 0, cg: CGFloat = 0, cb: CGFloat = 0, ca: CGFloat = 0
            candidate.getRed(&cr, green: &cg, blue: &cb, alpha: &ca)
            let dist = (tr - cr) * (tr - cr)
                     + (tg - cg) * (tg - cg)
                     + (tb - cb) * (tb - cb)
            if dist < minDist {
                minDist = dist
                closest = candidate
            }
        }

        return closest
    }
}
