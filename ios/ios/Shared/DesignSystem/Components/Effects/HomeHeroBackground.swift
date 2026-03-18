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
                    .frame(width: 350, height: 350)
                    .offset(x: animate ? 60 : -60, y: animate ? -120 : -40)
                    .blur(radius: 100)

                Circle()
                    .fill(PrototypeTheme.accent.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .offset(x: animate ? -80 : 80, y: animate ? 150 : 80)
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
