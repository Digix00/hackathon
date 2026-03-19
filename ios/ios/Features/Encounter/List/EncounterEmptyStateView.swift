import SwiftUI

struct EncounterEmptyStateView: View {
    let errorMessage: String?
    let isLoading: Bool
    let onRefresh: () -> Void

    @State private var isVisible = false
    @State private var seed = Int.random(in: 0...1000)

    var body: some View {
        ZStack {
            // 1. 有機的な背景のゆらぎ
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let seedPhase = Double(seed % 11) * 0.37
                
                ZStack {
                    AuraNode(
                        color: themeColor.opacity(0.12),
                        offset: CGSize(
                            width: sin(t * 0.4 + seedPhase) * 50,
                            height: cos(t * 0.3 + seedPhase) * 30
                        ),
                        scale: 1.2 + sin(t * 0.5) * 0.1,
                        blur: 80
                    )
                    
                    AuraNode(
                        color: themeColor.opacity(0.08),
                        offset: CGSize(
                            width: cos(t * 0.5 + seedPhase * 1.5) * 60,
                            height: sin(t * 0.4 + seedPhase * 0.8) * 40
                        ),
                        scale: 0.9 + cos(t * 0.6) * 0.15,
                        blur: 100
                    )
                }
            }

            // 2. 浮遊するコネクション・ドット
            ForEach(0..<6, id: \.self) { i in
                FloatingNode(index: i, color: themeColor.opacity(0.2))
            }

            // 3. メインコンテンツ
            VStack(spacing: 60) {
                // センターシンボル
                ZStack {
                    // 外側の波紋
                    Circle()
                        .stroke(themeColor.opacity(0.15), lineWidth: 1)
                        .frame(width: 160, height: 160)
                        .scaleEffect(isVisible ? 1.4 : 0.8)
                        .opacity(isVisible ? 0 : 0.6)
                        .animation(.easeOut(duration: 4).repeatForever(autoreverses: false), value: isVisible)

                    // 内側のコア
                    ZStack {
                        Circle()
                            .fill(PrototypeTheme.surface)
                            .frame(width: 80, height: 80)
                            .shadow(color: themeColor.opacity(0.1), radius: 30, x: 0, y: 15)

                        if isLoading {
                            ProgressView()
                                .tint(themeColor)
                        } else {
                            Image(systemName: iconName)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(themeColor.gradient)
                                .symbolRenderingMode(.hierarchical)
                                .symbolEffect(.pulse, options: .repeating, isActive: errorMessage == nil)
                        }
                    }
                }

                // テキストセクション
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(eyebrowText)
                            .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                            .kerning(4)
                            .foregroundStyle(themeColor.opacity(0.5))

                        Text(titleText)
                            .font(PrototypeTheme.Typography.font(size: 22, weight: .black, role: .primary))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                    }

                    Text(descriptionText)
                        .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 56)
                        .opacity(0.7)
                }

                if errorMessage != nil {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        onRefresh()
                    }) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .black))
                            }
                            
                            Text("RETRY CONNECTION")
                                .font(PrototypeTheme.Typography.font(size: 12, weight: .black, role: .data))
                                .kerning(2)
                        }
                        .foregroundStyle(themeColor)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(themeColor.opacity(0.06))
                        )
                    }
                    .buttonStyle(EncounterScaleButtonStyle())
                    .disabled(isLoading)
                    .padding(.top, 12)
                }
            }
            .offset(y: -20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2)) {
                isVisible = true
            }
        }
    }

    private var themeColor: Color {
        errorMessage == nil ? PrototypeTheme.info : PrototypeTheme.error
    }

    private var iconName: String {
        if errorMessage != nil {
            return "exclamationmark.triangle.fill"
        }
        return "sensor.tag.radiowaves.forward.fill"
    }

    private var eyebrowText: String {
        if errorMessage != nil {
            return "DATA ERROR"
        }
        return "SILENT CITY"
    }

    private var titleText: String {
        if errorMessage != nil {
            return "読み込みに失敗しました"
        }
        return "まだ静かな街角"
    }

    private var descriptionText: String {
        if let errorMessage {
            return errorMessage
        }
        return "あなたの周囲 50m には、まだ音楽の響きが届いていないようです。ゆっくりと歩きながら、新しい共鳴を待ちましょう。"
    }
}

// MARK: - Supporting Views

private struct AuraNode: View {
    let color: Color
    let offset: CGSize
    let scale: CGFloat
    let blur: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 300, height: 300)
            .scaleEffect(scale)
            .offset(offset)
            .blur(radius: blur)
    }
}

private struct FloatingNode: View {
    let index: Int
    let color: Color
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    @State private var hasInitialized = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 4...8))
            .position(position)
            .opacity(opacity)
            .onAppear {
                if !hasInitialized {
                    initializePosition()
                    animate()
                    hasInitialized = true
                }
            }
    }

    private func initializePosition() {
        let screen = UIScreen.main.bounds
        position = CGPoint(
            x: CGFloat.random(in: 0...screen.width),
            y: CGFloat.random(in: 0...screen.height)
        )
    }

    private func animate() {
        withAnimation(.easeInOut(duration: Double.random(in: 4...8)).repeatForever(autoreverses: true)) {
            position.x += CGFloat.random(in: -50...50)
            position.y += CGFloat.random(in: -50...50)
            opacity = Double.random(in: 0.2...0.6)
        }
    }
}
