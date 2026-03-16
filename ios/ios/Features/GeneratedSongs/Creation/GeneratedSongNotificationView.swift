import SwiftUI

struct GeneratedSongNotificationView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            DynamicBackground(baseColor: .indigo)
            
            VStack(spacing: 32) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .blur(radius: 30)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    MockArtworkView(color: .indigo, symbol: "sparkles", size: 120)
                        .shadow(color: .indigo.opacity(0.8), radius: isAnimating ? 40 : 20, x: 0, y: 15)
                        .rotationEffect(.degrees(isAnimating ? 8 : -8))
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
                }
                .onAppear {
                    isAnimating = true
                }
                
                VStack(spacing: 16) {
                    Text("新しい曲が生まれました")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white.opacity(0.7))
                        .kerning(2.0)
                    
                    Text("「夜明けの詩」")
                        .font(.system(size: 36, weight: .black))
                        .foregroundStyle(.white)
                    
                    Text("渋谷でのすれ違いから生まれた曲です。")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    PrimaryButton(title: "今すぐ聴く", systemImage: "play.fill") {}
                    Button("あとで") {}
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(32)
        }
    }
}

