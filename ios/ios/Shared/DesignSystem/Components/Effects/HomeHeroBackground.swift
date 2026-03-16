import SwiftUI

struct HomeHeroBackground: View {
    let baseColor: Color
    @State private var animate = false

    var body: some View {
        ZStack {
            PrototypeTheme.background

            Group {
                Circle()
                    .fill(baseColor.opacity(0.3))
                    .frame(width: 500, height: 500)
                    .offset(x: animate ? 100 : -100, y: animate ? -180 : -80)
                    .blur(radius: 100)

                Circle()
                    .fill(PrototypeTheme.accent.opacity(0.12))
                    .frame(width: 420, height: 420)
                    .offset(x: animate ? -120 : 120, y: animate ? 220 : 120)
                    .blur(radius: 110)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}
