import SwiftUI

struct DynamicBackground: View {
    let baseColor: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            PrototypeTheme.background.ignoresSafeArea()

            // Deep Layer Blob
            Circle()
                .fill(baseColor.opacity(0.18))
                .frame(width: 650, height: 650)
                .offset(x: animate ? 60 : -60, y: animate ? -120 : 120)
                .blur(radius: 90)

            // Dynamic Accent Blob
            Circle()
                .fill(baseColor.opacity(0.15))
                .frame(width: 450, height: 450)
                .offset(x: animate ? -140 : 140, y: animate ? 170 : -70)
                .blur(radius: 110)

            // Texture overlay
            DotGridBackground()
                .opacity(0.25)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
        .ignoresSafeArea()
    }
}
