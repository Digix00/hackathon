import SwiftUI

struct InsightsBackground: View {
    let colors: [Color]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var timelineInterval: TimeInterval {
        reduceMotion ? 1.0 / 8.0 : 1.0 / 20.0
    }

    var body: some View {
        ZStack {
            PrototypeTheme.background.ignoresSafeArea()

            encounterInspiredAura(colors: palette)

            PerspectiveStrataView(timelineInterval: timelineInterval)

            PrismaticSweepView(timelineInterval: timelineInterval, accentColor: palette[0])
        }
    }

    private var palette: [Color] {
        let filtered = Array(colors.prefix(4))
        return filtered.isEmpty
            ? [PrototypeTheme.accent, PrototypeTheme.info, PrototypeTheme.success]
            : filtered
    }

    private func encounterInspiredAura(colors: [Color]) -> some View {
        TimelineView(.periodic(from: .now, by: timelineInterval)) { timeline in
            let metrics = AuraMetrics(time: timeline.date.timeIntervalSinceReferenceDate)
            let primary = colors[0]
            let secondary = colors.count > 1 ? colors[1] : primary
            let tertiary = colors.count > 2 ? colors[2] : secondary

            GeometryReader { proxy in
                AuraLayerGroup(
                    size: proxy.size,
                    primary: primary,
                    secondary: secondary,
                    tertiary: tertiary,
                    metrics: metrics
                )
            }
        }
    }
}

private struct PerspectiveStrataView: View {
    let timelineInterval: TimeInterval

    var body: some View {
        TimelineView(.periodic(from: .now, by: timelineInterval)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.5, y: size.height * 0.34)
                let ringPulse = 1 + CGFloat(sin(t * 0.36) * 0.05)

                drawPerspectiveLines(context: &context, size: size, center: center, time: t)
                drawPulseRings(context: &context, center: center, ringPulse: ringPulse)
            }
        }
    }

    private func drawPerspectiveLines(
        context: inout GraphicsContext,
        size: CGSize,
        center: CGPoint,
        time: TimeInterval
    ) {
        for i in 0..<28 {
            let angle = Double(i) * 12.8 * .pi / 180.0 + sin(time * 0.05) * 0.03
            var path = Path()
            path.move(to: center)
            let xOffset = CGFloat(cos(angle)) * size.height * 1.35
            let yOffset = CGFloat(sin(angle)) * size.height * 1.35
            let destination = CGPoint(
                x: center.x + xOffset,
                y: center.y + yOffset
            )
            path.addLine(to: destination)
            context.stroke(path, with: .color(PrototypeTheme.textSecondary.opacity(0.028)), lineWidth: 0.5)
        }
    }

    private func drawPulseRings(
        context: inout GraphicsContext,
        center: CGPoint,
        ringPulse: CGFloat
    ) {
        for i in 1..<7 {
            let radius = CGFloat(i) * 96 * ringPulse
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            let ring = Path(ellipseIn: rect)
            context.stroke(ring, with: .color(PrototypeTheme.textSecondary.opacity(0.022)), lineWidth: 0.6)
        }
    }
}

private struct PrismaticSweepView: View {
    let timelineInterval: TimeInterval
    let accentColor: Color

    var body: some View {
        TimelineView(.periodic(from: .now, by: timelineInterval)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let scanPos = CGFloat((sin(t * 0.18) + 1) / 2)

            GeometryReader { proxy in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, accentColor.opacity(0.12), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * 0.72)
                    .rotationEffect(.degrees(-32))
                    .offset(x: proxy.size.width * (scanPos - 0.55), y: -proxy.size.height * 0.04)
                    .blur(radius: 60)
                    .blendMode(.plusDarker)
            }
        }
    }
}

private struct AuraLayerGroup: View {
    let size: CGSize
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let metrics: AuraMetrics

    var body: some View {
        ZStack {
            PrimaryAuraLayer(color: primary, size: size, metrics: metrics)
            SecondaryAuraLayer(color: secondary, size: size, metrics: metrics)
            TertiaryAuraLayer(color: tertiary, size: size, metrics: metrics)
            ShimmerAuraLayer(size: size, metrics: metrics)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .saturation(1.06)
    }
}

private struct PrimaryAuraLayer: View {
    let color: Color
    let size: CGSize
    let metrics: AuraMetrics

    var body: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(0.26),
                        color.opacity(0.10),
                        color.opacity(0.01)
                    ],
                    center: .center,
                    startRadius: 18,
                    endRadius: 220
                )
            )
            .frame(width: 420, height: 360)
            .scaleEffect(metrics.primaryPulse)
            .blur(radius: 72)
            .offset(
                x: -size.width * 0.18 + metrics.primaryOffset.width,
                y: -size.height * 0.12 + metrics.primaryOffset.height
            )
    }
}

private struct SecondaryAuraLayer: View {
    let color: Color
    let size: CGSize
    let metrics: AuraMetrics

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(0.22),
                        color.opacity(0.08),
                        .clear
                    ],
                    center: .center,
                    startRadius: 12,
                    endRadius: 180
                )
            )
            .frame(width: 300, height: 300)
            .scaleEffect(metrics.secondaryPulse)
            .blur(radius: 64)
            .offset(
                x: size.width * 0.26 + metrics.secondaryOffset.width,
                y: -size.height * 0.02 + metrics.secondaryOffset.height
            )
    }
}

private struct TertiaryAuraLayer: View {
    let color: Color
    let size: CGSize
    let metrics: AuraMetrics

    var body: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.18),
                        color.opacity(0.08),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 260, height: 420)
            .scaleEffect(x: 0.92, y: metrics.tertiaryPulse)
            .rotationEffect(metrics.tertiaryRotation)
            .blur(radius: 70)
            .offset(
                x: metrics.tertiaryOffset.width,
                y: size.height * 0.24 + metrics.tertiaryOffset.height
            )
    }
}

private struct ShimmerAuraLayer: View {
    let size: CGSize
    let metrics: AuraMetrics

    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.18))
            .frame(width: 144, height: 144)
            .blur(radius: 34)
            .opacity(metrics.shimmerOpacity)
            .offset(
                x: metrics.shimmerOffset.width,
                y: metrics.shimmerOffset.height - size.height * 0.06
            )
    }
}

private struct AuraMetrics {
    let primaryOffset: CGSize
    let secondaryOffset: CGSize
    let tertiaryOffset: CGSize
    let shimmerOffset: CGSize
    let primaryPulse: CGFloat
    let secondaryPulse: CGFloat
    let tertiaryPulse: CGFloat
    let tertiaryRotation: Angle
    let shimmerOpacity: CGFloat

    init(time: TimeInterval) {
        primaryOffset = CGSize(
            width: CGFloat(sin(time * 0.19) * 84),
            height: CGFloat(cos(time * 0.16) * 54)
        )
        secondaryOffset = CGSize(
            width: CGFloat(cos(time * 0.14 + 1.1) * 120),
            height: CGFloat(sin(time * 0.17 + 0.5) * 88)
        )
        tertiaryOffset = CGSize(
            width: CGFloat(sin(time * 0.12 + 2.1) * 142),
            height: CGFloat(cos(time * 0.13 + 1.4) * 112)
        )
        shimmerOffset = CGSize(
            width: CGFloat(sin(time * 0.28 + 0.8) * 170),
            height: CGFloat(cos(time * 0.22 + 1.7) * 120)
        )
        primaryPulse = 1 + CGFloat(sin(time * 0.24) * 0.08)
        secondaryPulse = 1 + CGFloat(cos(time * 0.21 + 0.7) * 0.12)
        tertiaryPulse = 1 + CGFloat(sin(time * 0.18 + 1.5) * 0.10)
        tertiaryRotation = .degrees(sin(time * 0.17 + 0.6) * 18)
        shimmerOpacity = 0.18 + CGFloat(sin(time * 0.32) * 0.06)
    }
}
