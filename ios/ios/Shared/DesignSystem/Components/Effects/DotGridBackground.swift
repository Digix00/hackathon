import SwiftUI

struct DotGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let dotSize: CGFloat = 1.0
            let spacing: CGFloat = 28

            for x in stride(from: spacing/2, through: size.width, by: spacing) {
                for y in stride(from: spacing/2, through: size.height, by: spacing) {
                    let rect = CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(PrototypeTheme.textSecondary.opacity(0.15)))
                }
            }
        }
        .ignoresSafeArea()
    }
}
