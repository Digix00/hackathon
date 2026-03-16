import SwiftUI

struct ParticleModifier: ViewModifier {
    @State private var time = 0.0
    private let duration: Double = 20.0

    func body(content: Content) -> some View {
        content
            .overlay(
                Canvas { context, size in
                    for i in 0..<30 {
                        let isEven = i % 2 == 0
                        let speed = isEven ? 0.05 : 0.08
                        let xOffset = sin(time * speed + Double(i)) * size.width * 0.4
                        let yOffset = -time * speed * size.height + Double(i * 20)

                        let normalizedY = yOffset.truncatingRemainder(dividingBy: size.height * 1.5)
                        let y = size.height - (normalizedY < 0 ? normalizedY + size.height * 1.5 : normalizedY)
                        let x = size.width / 2 + xOffset

                        let rect = CGRect(x: x, y: y, width: 3, height: 3)
                        context.opacity = 0.3 * sin(time * 2 + Double(i)) + 0.3
                        context.fill(Path(ellipseIn: rect), with: .color(.white))
                    }
                }
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    time = duration * 10
                }
            }
    }
}

extension View {
    func particleEffect() -> some View {
        modifier(ParticleModifier())
    }
}
