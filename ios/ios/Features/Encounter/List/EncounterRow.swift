import SwiftUI

struct EncounterRow: View {
    let encounter: Encounter
    let isFixed: Bool
    
    private var seed: Int { abs(encounter.id.hashValue) }

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
                    jacketView(size: 80)
                        .offset(x: artworkOffset.x, y: artworkOffset.y)
                        .rotationEffect(.degrees(Double(horizontalShift) / 2))
                    
                    // ユーザー名（メイン・マス）
                    VStack(alignment: horizontalShift > 0 ? .leading : .trailing, spacing: 4) {
                        Text(encounter.userName)
                            .font(PrototypeTheme.Typography.font(size: 40 * nameLengthWeight, weight: .black, role: .primary))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .tracking(-1.5)
                        
                        Text(encounter.track.title)
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
        MockArtworkView(color: encounter.track.color, symbol: "music.note", size: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .shadow(color: encounter.track.color.opacity(0.1), radius: 20, x: 0, y: 10)
    }

    private var auraView: some View {
        Circle()
            .fill(encounter.track.color.opacity(0.05))
            .frame(width: 300, height: 300)
            .blur(radius: auraBlurRadius)
            .offset(x: horizontalShift * 2, y: 0)
    }
}
