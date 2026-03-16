import SwiftUI

struct HomeHeroPage: View {
    let state: HomeScreenState
    let isMotionActive: Bool

    @Environment(\.topSafeAreaInset) private var topSafeArea
    @Environment(\.bottomSafeAreaInset) private var bottomSafeArea
    @StateObject private var motion = MotionManager()

    private var heroColor: Color {
        state.featuredTrack?.color ?? PrototypeTheme.surfaceElevated
    }

    var body: some View {
        ZStack {
            // Background Layer
            ZStack {
                PrototypeTheme.background.ignoresSafeArea()
                HomeHeroBackground(baseColor: heroColor)
                    .ignoresSafeArea()
                
                // Large background text - adjusted for safe area to keep visual center
                Text("TOKYO")
                    .font(.system(size: 140, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.03))
                    .rotationEffect(.degrees(-90))
                    .offset(x: -150)
                    .allowsHitTesting(false)
                    .offset(x: CGFloat(motion.roll * -10), y: CGFloat(motion.pitch * -10))
            }
            .offset(x: CGFloat(motion.roll * -30), y: CGFloat(motion.pitch * -30))

            // Content Layer
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("35.6812° N, 139.7671° E")
                            .prototypeFont(size: 10, weight: .bold, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                        Text("TOKYO / SHIBUYA")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.4))
                            .kerning(1.5)
                    }
                    Spacer()

                    HStack(spacing: 8) {
                        Circle()
                            .fill(PrototypeTheme.accent)
                            .frame(width: 6, height: 6)

                        Text("検知中")
                            .font(.system(size: 10, weight: .black))
                            .kerning(1.2)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(PrototypeTheme.surface.opacity(0.4))
                    .clipShape(Capsule())
                }
                .padding(.top, max(16, topSafeArea + 4))

                Spacer()

                NavigationLink {
                    SearchView()
                } label: {
                    FeaturedTrackHeroCard(
                        track: state.featuredTrack, 
                        motionX: CGFloat(motion.roll * 20), 
                        motionY: CGFloat(motion.pitch * 20)
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                Spacer()

                VStack(spacing: 12) {
                    Text("上にスワイプして詳細を見る")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.5))
                        .kerning(2.0)

                    Capsule()
                        .fill(PrototypeTheme.border.opacity(0.6))
                        .frame(width: 40, height: 4)
                }
                .padding(.bottom, max(24, bottomSafeArea + 8))
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PrototypeTheme.background)
        .onAppear {
            if isMotionActive {
                motion.startUpdates()
            }
        }
        .onChange(of: isMotionActive) { isActive in
            if isActive {
                motion.startUpdates()
            } else {
                motion.stopUpdates()
            }
        }
        .onDisappear {
            motion.stopUpdates()
        }
    }
}
