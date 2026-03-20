import UIKit
import SwiftUI

/// アートワーク画像から代表色を抽出し、テンプレパレット10色の中から
/// 最も近い色を返すサービス。URLSesion + NSCache でキャッシュ済み。
actor ArtworkColorExtractor {
    static let shared = ArtworkColorExtractor()

    private let cache = NSCache<NSString, UIColor>()

    /// テンプレパレット 10 色（知覚的に均等な間隔で選定）
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

    /// アートワーク URL から代表色を抽出し、テンプレパレットで最近傍の色を返す。
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
                  let dominant = dominantColor(from: image) else { return nil }

            let matched = closestTemplateColor(to: dominant)
            cache.setObject(matched, forKey: urlString as NSString)
            return Color(matched)
        } catch {
            return nil
        }
    }

    // MARK: - Private

    /// 画像を 8×8 に縮小してピクセルをサンプリングし、
    /// 彩度 × 輝度スコアが最大のピクセルの色を代表色として返す。
    /// 暗すぎる・白すぎるピクセルは低スコアになるため自然にスキップされる。
    private func dominantColor(from image: UIImage) -> UIColor? {
        let side = 8
        let size = CGSize(width: side, height: side)

        // Core Graphics で RGBA 形式に正規化してリサイズ
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

        ctx.draw(
            image.cgImage ?? UIGraphicsImageRenderer(size: size).image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }.cgImage!,
            in: CGRect(origin: .zero, size: size)
        )

        guard let data = ctx.data else { return nil }
        let ptr = data.bindMemory(to: UInt8.self, capacity: side * side * 4)

        var bestColor: UIColor = .gray
        var maxScore: CGFloat = -1

        for i in 0..<(side * side) {
            let r = CGFloat(ptr[i * 4])     / 255.0
            let g = CGFloat(ptr[i * 4 + 1]) / 255.0
            let b = CGFloat(ptr[i * 4 + 2]) / 255.0

            let pixel = UIColor(red: r, green: g, blue: b, alpha: 1)
            var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
            pixel.getHue(&h, saturation: &s, brightness: &v, alpha: &a)

            // 彩度が高く、かつ輝度が中間帯（0.2〜0.85）にある色を優先
            guard v > 0.2, v < 0.85 else { continue }
            let score = s * v
            if score > maxScore {
                maxScore = score
                bestColor = pixel
            }
        }

        return bestColor
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
