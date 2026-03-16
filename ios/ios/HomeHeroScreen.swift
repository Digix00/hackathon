import SwiftUI

private struct DynamicBlurBackground: View {
    let baseColor: Color

    var body: some View {
        ZStack {
            PrototypeTheme.background


            Color.white.opacity(0.01)
                .background(
                    Image(systemName: "sparkles")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(0.02)
                        .blendMode(.overlay)
                )

            DotGridBackground()
                .opacity(0.2)
        }
        .particleEffect()
        .ignoresSafeArea()
    }
}

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
            PrototypeTheme.background
                .ignoresSafeArea()

            DynamicBlurBackground(baseColor: heroColor)

            Text("TOKYO")
                .font(.system(size: 140, weight: .black))
                .foregroundStyle(Color.white.opacity(0.03))
                .rotationEffect(.degrees(-90))
                .offset(x: -150)
                .allowsHitTesting(false)

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
                .padding(.top, topSafeArea + 8)

                Spacer()

                NavigationLink {
                    SearchView()
                } label: {
                    FeaturedTrackHeroCard(track: state.featuredTrack, motionX: CGFloat(motion.roll * 20), motionY: CGFloat(motion.pitch * 20))
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
                .padding(.bottom, max(24, bottomSafeArea + 16))
            }
            .padding(.horizontal, 32)
        }
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
        .ignoresSafeArea()
    }
}

private struct FeaturedTrackHeroCard: View {
    let track: Track?
    let motionX: CGFloat
    let motionY: CGFloat
    @State private var isPulsing = false
    @Environment(\.heroNamespace) private var heroNamespace

    var body: some View {
        VStack(spacing: 48) {
            if let track {
                VStack(spacing: 40) {
                    ZStack {
                        Circle()
                            .fill(track.color.opacity(0.15))
                            .frame(width: 340, height: 340)
                            .scaleEffect(isPulsing ? 1.15 : 1.0)
                            .blur(radius: isPulsing ? 32 : 20)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isPulsing)

                        Circle()
                            .stroke(track.color.opacity(0.15), lineWidth: 1)
                            .frame(width: 300, height: 300)

                        Circle()
                            .stroke(track.color.opacity(0.08), lineWidth: 1)
                            .frame(width: 260, height: 260)

                        MockArtworkView(color: track.color, symbol: "music.note", size: 240)
                            .shadow(color: track.color.opacity(0.2), radius: 30, x: 0, y: 15)
                            .offset(x: motionX, y: motionY)
                            .matchedGeometryEffect(id: "hero_artwork_\(track.id)", in: heroNamespace)
                    }
                    .onAppear {
                        isPulsing = true
                    }

                    VStack(spacing: 12) {
                        Text("いまシェア中")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(track.color.opacity(0.7))
                            .kerning(1.5)

                        Text(track.title)
                            .font(.system(size: 38, weight: .black))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .tracking(-1.0)
                            .matchedGeometryEffect(id: "hero_title_\(track.id)", in: heroNamespace)

                        Text(track.artist)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .matchedGeometryEffect(id: "hero_artist_\(track.id)", in: heroNamespace)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.horizontal, 12)
                }
            } else {
                VStack(spacing: 32) {
                    Circle()
                        .fill(PrototypeTheme.surfaceMuted)
                        .frame(width: 140, height: 140)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 40, weight: .light))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                        .offset(x: motionX, y: motionY)

                    Text("曲を設定")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .kerning(1.2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
