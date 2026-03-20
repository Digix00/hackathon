import SwiftUI

struct HomePage: View {
    let state: HomeScreenState
    let isMotionActive: Bool
    var onReload: (() -> Void)? = nil

    @Environment(\.topSafeAreaInset) private var topSafeArea
    @Environment(\.bottomSafeAreaInset) private var bottomSafeArea
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator
    @EnvironmentObject private var bleManager: BLEManager
    @StateObject private var motion = MotionManager()

    private var homeColor: Color {
        state.featuredTrack?.color ?? PrototypeTheme.surfaceElevated
    }

    private var bleStatusText: String {
        guard bleCoordinator.bleEnabled else { return "BLE OFF" }

        switch bleManager.state {
        case .poweredOn:
            return bleManager.isScanning ? "SCANNING" : "STANDBY"
        case .poweredOff:
            return "BT OFF"
        case .unauthorized:
            return "NO ACCESS"
        case .unsupported:
            return "UNSUPPORTED"
        case .unknown:
            return "CHECKING"
        }
    }

    private var bleStatusColor: Color {
        guard bleCoordinator.bleEnabled else { return PrototypeTheme.textTertiary }

        switch bleManager.state {
        case .poweredOn:
            return bleManager.isScanning ? PrototypeTheme.success : PrototypeTheme.accent
        case .poweredOff, .unauthorized, .unsupported:
            return PrototypeTheme.warning
        case .unknown:
            return PrototypeTheme.textSecondary
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Layer
                ZStack {
                    PrototypeTheme.background
                    HomeBackground(baseColor: homeColor)

                    // Extremely subtle background text, fixed to avoid clipping
                    Text("TOKYO")
                        .font(.system(size: 140, weight: .black))
                        .foregroundStyle(Color.white.opacity(0.012))
                        .rotationEffect(.degrees(-90))
                        .offset(x: -160)
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                .offset(x: CGFloat(motion.roll * -15), y: CGFloat(motion.pitch * -15))

                // Content Layer
                VStack {
                // Top Info Bar - adjusted padding and spacing to prevent overflow
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("35.6812° N, 139.7671° E")
                            .prototypeFont(size: 8.5, weight: .bold, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.4))
                        Text("SHIBUYA / TOKYO")
                            .font(.system(size: 8.5, weight: .black))
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.2))
                            .kerning(1.5)
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(bleStatusColor.opacity(0.8))
                            .frame(width: 3.5, height: 3.5)

                        Text(bleStatusText)
                            .font(.system(size: 8.5, weight: .black))
                            .kerning(1.2)
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(PrototypeTheme.surface.opacity(0.4))
                    )
                }
                .padding(.top, max(12, topSafeArea)) // Corrected top padding for safe area

                Spacer()

                NavigationLink {
                    SearchView()
                } label: {
                    HomeFeaturedTrackCard(
                        track: state.featuredTrack,
                        motionX: CGFloat(motion.roll * 12),
                        motionY: CGFloat(motion.pitch * 12)
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                Spacer()

                // Bottom Hint
                VStack(spacing: 12) {
                    Text("SWIPE UP TO DISCOVER")
                        .font(.system(size: 8.5, weight: .black))
                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.3))
                        .kerning(2.5)

                    Capsule()
                        .fill(PrototypeTheme.border.opacity(0.3))
                        .frame(width: 28, height: 2.5)
                }
                .padding(.bottom, max(24, bottomSafeArea + 8))
            }
            .padding(.horizontal, 28) // Balanced padding for safety and breathing room
            }
        }
        .onAppear {
            onReload?()
            if isMotionActive {
                motion.startUpdates()
            }
        }
        .onChange(of: isMotionActive) {
            if isMotionActive {
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
