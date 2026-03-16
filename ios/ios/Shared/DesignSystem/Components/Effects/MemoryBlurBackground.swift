import SwiftUI

struct MemoryBlurBackground: View {
    let colors: [Color]
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // ベース背景
            PrototypeTheme.background
            
            // ブラーレイヤーをひとまとめにして描画最適化
            ZStack {
                ForEach(Array(colors.prefix(6).enumerated()), id: \.offset) { index, color in
                    Circle()
                        .fill(color)
                        // 彩度を調整して濁りを回避
                        .saturation(1.4)
                        .frame(width: 550, height: 550)
                        .offset(
                            x: (animate ? animateOffset(for: index).x : staticOffset(for: index).x),
                            y: (animate ? animateOffset(for: index).y : staticOffset(for: index).y)
                        )
                        .opacity(0.18)
                        .blur(radius: 100)
                        .blendMode(.plusLighter)
                }
            }
            .drawingGroup() // 描画計算を一本化
            
            // 質感を整えるオーバーレイ
            ZStack {
                // 微細な粒面テクスチャ（ノイズ）
                Color.black.opacity(0.03)
                
                // ドットグリッドの再利用（他の画面との親和性）
                DotGridBackground()
                    .opacity(0.08)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
    
    private func staticOffset(for index: Int) -> CGPoint {
        let offsets: [CGPoint] = [
            CGPoint(x: -280, y: -250),
            CGPoint(x: 280, y: 350),
            CGPoint(x: -200, y: 500),
            CGPoint(x: 250, y: -450),
            CGPoint(x: 0, y: 150),
            CGPoint(x: -120, y: -500)
        ]
        return offsets[index % offsets.count]
    }

    private func animateOffset(for index: Int) -> CGPoint {
        let base = staticOffset(for: index)
        return CGPoint(x: base.x * 0.8, y: base.y * 1.1)
    }
}
