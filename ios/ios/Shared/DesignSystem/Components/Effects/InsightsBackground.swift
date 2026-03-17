import SwiftUI

struct InsightsBackground: View {
    let colors: [Color]
    @State private var pulse: CGFloat = 0
    @State private var scanPos: CGFloat = -0.5

    var body: some View {
        ZStack {
            // 1. The Deep Void (ベース)
            PrototypeTheme.background.ignoresSafeArea()

            // 2. Perspective Strata (透視投影される音の地層)
            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.4)
                
                // 放射状のパースライン
                for i in 0..<36 {
                    let angle = Double(i) * 10.0 * .pi / 180.0
                    var path = Path()
                    path.move(to: center)
                    let dest = CGPoint(
                        x: center.x + cos(angle) * size.height * 1.5,
                        y: center.y + sin(angle) * size.height * 1.5
                    )
                    path.addLine(to: dest)
                    context.stroke(path, with: .color(PrototypeTheme.textSecondary.opacity(0.04)), lineWidth: 0.5)
                }
                
                // 同心円状のパルス
                for i in 1..<8 {
                    let radius = CGFloat(i) * 100 * (1 + pulse * 0.05)
                    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                    context.stroke(Path(ellipseIn: rect), with: .color(PrototypeTheme.textSecondary.opacity(0.03)), lineWidth: 0.5)
                }
            }

            // 3. Prismatic Rays
            if let color = colors.first {
                GeometryReader { proxy in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, color.opacity(0.12), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * 0.8)
                        .rotationEffect(.degrees(-35))
                        .offset(x: proxy.size.width * scanPos, y: 0)
                        .blur(radius: 60)
                        .blendMode(.plusDarker)
                }
            }

            // 4. Urban Constellations
            ConstellationView(colors: colors)
            
            // 5. Minimal Grain Texture
            DotGridBackground()
                .opacity(0.08)
                .blendMode(.overlay)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                pulse = 1.0
            }
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                scanPos = 1.8
            }
        }
    }
}

private struct ConstellationView: View {
    let colors: [Color]
    @State private var move: CGFloat = 0
    
    var body: some View {
        Canvas { context, size in
            let points = seedPoints(for: size)
            
            // 繋がりを描画
            for i in 0..<points.count {
                for j in i+1..<points.count {
                    let animatedPtI = animatePoint(points[i], size: size)
                    let animatedPtJ = animatePoint(points[j], size: size)
                    let d = distance(animatedPtI, animatedPtJ)
                    
                    if d < 140 {
                        let alpha = 0.06 * (1.0 - (d / 140.0))
                        var path = Path()
                        path.move(to: animatedPtI)
                        path.addLine(to: animatedPtJ)
                        context.stroke(path, with: .color(PrototypeTheme.textSecondary.opacity(alpha)), lineWidth: 0.4)
                    }
                }
            }
            
            // ポイントを描画
            for (i, pt) in points.enumerated() {
                let animatedPt = animatePoint(pt, size: size)
                let baseColor = i < colors.count ? colors[i] : PrototypeTheme.accent
                let color = baseColor.opacity(0.3)
                
                let rect = CGRect(x: animatedPt.x - 1.5, y: animatedPt.y - 1.5, width: 3, height: 3)
                context.fill(Path(ellipseIn: rect), with: .color(color))
                
                // ほのかなグロー
                context.fill(Path(ellipseIn: rect.insetBy(dx: -3, dy: -3)), with: .color(color.opacity(0.05)))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
                move = 1.0
            }
        }
    }
    
    private func seedPoints(for size: CGSize) -> [CGPoint] {
        var pts: [CGPoint] = []
        for i in 0..<22 {
            pts.append(CGPoint(
                x: .random(in: 0...size.width, seed: i + 500),
                y: .random(in: 0...size.height, seed: i + 600)
            ))
        }
        return pts
    }
    
    private func animatePoint(_ pt: CGPoint, size: CGSize) -> CGPoint {
        CGPoint(
            x: pt.x + sin(move * .pi * 2 + pt.y * 0.02) * 25,
            y: pt.y + cos(move * .pi * 2 + pt.x * 0.02) * 25
        )
    }
    
    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
    }
}

private extension CGFloat {
    static func random(in range: ClosedRange<CGFloat>, seed: Int) -> CGFloat {
        var generator = SplitMix64(seed: UInt64(bitPattern: Int64(seed)))
        let value = CGFloat.random(in: 0...1, using: &generator)
        return range.lowerBound + (range.upperBound - range.lowerBound) * value
    }
}

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
