import SwiftUI

struct EncounterRow: View {
    let encounter: Encounter
    let isFixed: Bool
    
    private var seed: Int { abs(encounter.id.hashValue) }
    
    // --- プロフェッショナル・デザイン・エンジン ---
    
    // 1. 中央軸からの「振幅」を計算（重心を安定させるためのオフセット）
    private var horizontalShift: CGFloat {
        isFixed ? 0 : (CGFloat(seed % 40) - 20) // -20〜20の微細な揺らぎ
    }
    
    // 2. 名前の長さによる「視覚的質量」の補正
    private var nameLengthWeight: CGFloat {
        let count = encounter.userName.count
        return count <= 3 ? 1.3 : (count >= 8 ? 0.85 : 1.0)
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
                .padding(.bottom, 24)
                .offset(x: -horizontalShift * 0.5) // 本体と逆方向に振って均衡をとる

                // --- Main Layer: The Composition (ここがデザインの核) ---
                // 名前とジャケットを「対抗配置」し、中央で均衡させる
                ZStack(alignment: .center) {
                    
                    // ジャケット（アクセント・マス）
                    // 名前が右なら左、名前が左なら右へ自動配置
                    jacketView(size: 80)
                        .offset(x: horizontalShift > 0 ? -110 : 110, y: -10)
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
                .padding(.bottom, 32)

                // --- Bottom Layer: The Echo (想いの断片) ---
                if !encounter.lyric.isEmpty {
                    Text("“\(encounter.lyric)”")
                        .font(PrototypeTheme.Typography.font(size: 18, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textPrimary.opacity(0.7))
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 260)
                        .padding(.top, 16)
                        .offset(x: -horizontalShift * 0.3) // 微妙なズレで立体感を出す
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
            .blur(radius: 60)
            .offset(x: horizontalShift * 2, y: 0)
    }
}
