import SwiftUI

struct EncounterRow: View {
    let encounter: Encounter
    let isFixed: Bool
    let hideMatchedElements: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.encounterNamespace) private var namespace

    init(encounter: Encounter, isFixed: Bool, hideMatchedElements: Bool = false) {
        self.encounter = encounter
        self.isFixed = isFixed
        self.hideMatchedElements = hideMatchedElements
    }
    
    private var seed: Int {
        let magnitude = encounter.id.hashValue.magnitude
        return Int(magnitude % UInt(Int.max))
    }

    // --- プロフェッショナル・デザイン・エンジン ---

    // 名前の長さカテゴリー
    private enum NameLengthCategory {
        case short   // 1-3文字
        case medium  // 4-7文字
        case long    // 8文字以上
    }

    // 視覚的質量の計算結果
    private struct VisualMass {
        let text: CGFloat
        let artwork: CGFloat

        var total: CGFloat { text + artwork }
        var textRatio: CGFloat { text / total }
        var artworkRatio: CGFloat { artwork / total }
    }

    // 縦方向のスペーシング
    private struct VerticalSpacing {
        let metadataBottom: CGFloat
        let mainBottom: CGFloat
        let echoTop: CGFloat
    }

    // 1. 名前の長さカテゴリーを判定
    private var nameLengthCategory: NameLengthCategory {
        let count = encounter.userName.count
        if count <= 3 {
            return .short
        } else if count <= 7 {
            return .medium
        } else {
            return .long
        }
    }

    // 2. 視覚的質量を計算
    private var visualMass: VisualMass {
        let nameCount = CGFloat(encounter.userName.count)
        let fontSize = 40 * nameLengthWeight
        let textMass = nameCount * fontSize * 1.2 // 太さ係数
        let artworkMass: CGFloat = 80 * 80 * 1.0 // アートワークの質量
        return VisualMass(text: textMass, artwork: artworkMass)
    }

    // 3. 中央軸からの「振幅」を計算（名前の長さで動的に調整）
    private var horizontalShift: CGFloat {
        guard !isFixed else { return 0 }
        let baseShift = CGFloat(seed % 40) - 20 // -20〜20の微細な揺らぎ
        let amplitudeMultiplier: CGFloat = {
            switch nameLengthCategory {
            case .short: return 1.3  // 大きく振る
            case .medium: return 1.0  // 標準
            case .long: return 0.7    // 控えめに
            }
        }()
        return baseShift * amplitudeMultiplier
    }

    // 4. 名前の長さによる「視覚的質量」の補正（フォントサイズ）
    private var nameLengthWeight: CGFloat {
        switch nameLengthCategory {
        case .short: return 1.3   // 元の実装を維持
        case .medium: return 1.0  // 標準
        case .long: return 0.85   // 元の実装を維持
        }
    }

    // 5. アートワークのオフセット（重心バランスを考慮）
    private var artworkOffset: (x: CGFloat, y: CGFloat) {
        let baseDistance: CGFloat = {
            switch nameLengthCategory {
            case .short: return 120   // もう少し離す
            case .medium: return 140  // もう少し離す
            case .long: return 160    // もう少し離す
            }
        }()
        let xOffset = horizontalShift > 0 ? -baseDistance : baseDistance
        let yOffset: CGFloat = -10
        return (xOffset, yOffset)
    }

    // 6. メタデータのオフセット（カウンターウェイト）
    private var metadataOffset: CGFloat {
        guard !isFixed else { return 0 }
        // 質量比を使ってカウンターウェイトを調整
        let counterweightRatio = visualMass.textRatio * 0.6
        return -horizontalShift * counterweightRatio
    }

    // 7. エコーのオフセット（歌詞の長さと名前の長さを考慮）
    private var echoOffset: CGFloat {
        guard !isFixed else { return 0 }
        let echoProximity: CGFloat = {
            switch nameLengthCategory {
            case .short: return 0.4   // 凝縮感
            case .medium: return 0.3  // 標準
            case .long: return 0.2    // やや離す
            }
        }()
        return -horizontalShift * echoProximity
    }

    // 8. オーラのブラー半径（名前の長さで動的に変化）
    private var auraBlurRadius: CGFloat {
        switch nameLengthCategory {
        case .short: return 50   // 凝縮
        case .medium: return 60  // 標準
        case .long: return 70    // 拡散
        }
    }

    // 9. 縦方向のスペーシング（動的に調整）
    private var verticalSpacing: VerticalSpacing {
        switch nameLengthCategory {
        case .short:
            return VerticalSpacing(metadataBottom: 20, mainBottom: 28, echoTop: 12)
        case .medium:
            return VerticalSpacing(metadataBottom: 24, mainBottom: 32, echoTop: 16)
        case .long:
            return VerticalSpacing(metadataBottom: 28, mainBottom: 36, echoTop: 20)
        }
    }

    var body: some View {
        ZStack(alignment: .center) {
            // 背景のオーラ：重心を補強する環境光
            auraView

            VStack(alignment: .center, spacing: 0) {
                
                // --- Top Layer: Metadata (空間の起点) ---
                HStack(alignment: .center, spacing: 12) {
                    Text(encounter.relativeTime.uppercased())
                        .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                        .kerning(2)
                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.3))
                    
                    Rectangle()
                        .fill(encounter.track.color.opacity(0.2))
                        .frame(width: 30, height: 1)
                }
                .padding(.bottom, verticalSpacing.metadataBottom)
                .offset(x: metadataOffset) // 本体と逆方向に振って均衡をとる

                // --- Main Layer: The Composition (ここがデザインの核) ---
                // 名前とジャケットを「対抗配置」し、中央で均衡させる
                ZStack(alignment: .center) {
                    
                    // ジャケット（アクセント・マス）
                    // 名前が右なら左、名前が左なら右へ自動配置
                    Group {
                        if let namespace = namespace, !hideMatchedElements {
                            jacketView(size: 80)
                                .matchedGeometryEffect(id: "artwork-\(encounter.id)", in: namespace, isSource: true)
                        } else {
                            jacketView(size: 80)
                                .opacity(hideMatchedElements ? 0 : 1)
                        }
                    }
                    .offset(x: artworkOffset.x, y: artworkOffset.y)
                    .rotationEffect(.degrees(Double(horizontalShift) / 2))
                    
                    // ユーザー名（メイン・マス）
                    VStack(alignment: horizontalShift > 0 ? .leading : .trailing, spacing: 4) {
                        Group {
                            if let namespace = namespace, !hideMatchedElements {
                                Text(encounter.userName)
                                    .matchedGeometryEffect(id: "userName-\(encounter.id)", in: namespace, isSource: true)
                            } else {
                                Text(encounter.userName)
                                    .opacity(hideMatchedElements ? 0 : 1)
                            }
                        }
                        .font(PrototypeTheme.Typography.font(size: 40 * nameLengthWeight, weight: .black, role: .primary))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .tracking(-1.5)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.68)
                        .fixedSize(horizontal: false, vertical: true)

                        Group {
                            if let namespace = namespace, !hideMatchedElements {
                                Text(encounter.track.title)
                                    .matchedGeometryEffect(id: "trackTitle-\(encounter.id)", in: namespace, isSource: true)
                            } else {
                                Text(encounter.track.title)
                                    .opacity(hideMatchedElements ? 0 : 1)
                            }
                        }
                        .font(PrototypeTheme.Typography.font(size: 14, weight: .bold, role: .accent))
                        .italic()
                        .foregroundStyle(encounter.track.color)
                    }
                    .frame(width: 200, alignment: horizontalShift > 0 ? .leading : .trailing)
                    .offset(x: horizontalShift)
                }
                .padding(.bottom, verticalSpacing.mainBottom)

                // --- Bottom Layer: The Echo (想いの断片) ---
                if !encounter.lyric.isEmpty {
                    Text("“\(encounter.lyric)”")
                        .font(PrototypeTheme.Typography.font(size: 18, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textPrimary.opacity(0.7))
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 260)
                        .padding(.top, verticalSpacing.echoTop)
                        .offset(x: echoOffset) // 微妙なズレで立体感を出す
                }
            }
            .padding(.vertical, 56)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.001))
    }

    // --- 研ぎ澄まされたサブコンポーネント ---

    private func jacketView(size: CGFloat) -> some View {
        ArtworkPlaceholderView(color: encounter.track.color, symbol: "music.note", size: size, artwork: encounter.track.artwork)
            .shadow(color: encounter.track.color.opacity(0.1), radius: 20, x: 0, y: 10)
    }

    private var auraView: some View {
        let interval = reduceMotion ? 1.0 / 10.0 : 1.0 / 20.0

        return TimelineView(.animation(minimumInterval: interval)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let seedPhase = Double(seed % 11) * 0.37
            let driftX = CGFloat(sin(t * 0.78 + seedPhase) * 46)
            let driftY = CGFloat(cos(t * 0.62 + seedPhase * 1.3) * 32)
            let secondaryX = CGFloat(cos(t * 0.66 + seedPhase + 1.2) * 62)
            let secondaryY = CGFloat(sin(t * 0.56 + seedPhase * 0.9) * 40)
            let shimmerX = CGFloat(sin(t * 1.08 + seedPhase + 0.7) * 84)
            let shimmerY = CGFloat(cos(t * 0.84 + seedPhase * 1.1) * 46)
            let pulse = 1 + CGFloat(sin(t * 0.72 + seedPhase) * 0.12)
            let secondaryPulse = 1 + CGFloat(cos(t * 0.64 + seedPhase + 0.8) * 0.16)
            let tertiaryPulse = 1 + CGFloat(sin(t * 0.7 + seedPhase + 2.0) * 0.13)
            let shimmerOpacity = 0.24 + CGFloat(sin(t * 0.92 + seedPhase) * 0.10)

            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                encounter.track.color.opacity(0.44),
                                encounter.track.color.opacity(0.18),
                                encounter.track.color.opacity(0.02)
                            ],
                            center: .center,
                            startRadius: 12,
                            endRadius: 180
                        )
                    )
                    .frame(width: 340, height: 280)
                    .scaleEffect(pulse)
                    .blur(radius: auraBlurRadius * 0.94)
                    .offset(x: horizontalShift * 1.8 + driftX, y: driftY - 12)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                encounter.track.color.opacity(0.34),
                                encounter.track.color.opacity(0.10),
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 120
                        )
                    )
                    .frame(width: 228, height: 228)
                    .scaleEffect(secondaryPulse)
                    .blur(radius: auraBlurRadius * 0.62)
                    .offset(x: horizontalShift * 1.2 - secondaryX, y: -26 + secondaryY)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                encounter.track.color.opacity(0.28),
                                encounter.track.color.opacity(0.10),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 188, height: 248)
                    .scaleEffect(
                        x: 0.86 + CGFloat(sin(t * 0.66 + seedPhase) * 0.18),
                        y: 0.94 * tertiaryPulse
                    )
                    .rotationEffect(.degrees(sin(t * 0.61 + seedPhase) * 24))
                    .blur(radius: auraBlurRadius * 0.48)
                    .offset(x: horizontalShift * 2.2 + secondaryX * 1.02, y: 34 - secondaryY * 0.95)

                Circle()
                    .fill(Color.white.opacity(0.24))
                    .frame(width: 96, height: 96)
                    .blur(radius: 24)
                    .opacity(shimmerOpacity)
                    .offset(x: horizontalShift * 1.4 + shimmerX, y: shimmerY - 18)
            }
            .saturation(1.15)
            .rotationEffect(.degrees(sin(t * 0.24 + seedPhase) * 7))
        }
    }
}
