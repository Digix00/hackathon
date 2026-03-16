import SwiftUI

struct HomeHeroBackground: View {
    let baseColor: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            PrototypeTheme.background

            Group {
                Circle()
                    .fill(baseColor.opacity(0.4))
                    .frame(width: 450, height: 450)
                    .offset(x: animate ? 80 : -80, y: animate ? -150 : -50)
                    .blur(radius: 90)

                Circle()
                    .fill(PrototypeTheme.accent.opacity(0.15))
                    .frame(width: 380, height: 380)
                    .offset(x: animate ? -100 : 100, y: animate ? 200 : 100)
                    .blur(radius: 100)
            }
        }
        .particleEffect()
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
