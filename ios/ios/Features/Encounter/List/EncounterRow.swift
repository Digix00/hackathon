import SwiftUI

struct EncounterRow: View {
    let encounter: Encounter
    // ランダムな揺らぎを生むためのシード（idから生成）
    private var randomOffset: CGFloat {
        let hash = abs(encounter.id.hashValue)
        return CGFloat(hash % 40) - 20 // -20 to 20
    }

    var body: some View {
        HStack(spacing: 16) {
            MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 52, artwork: encounter.track.artwork)
                .shadow(color: encounter.track.color.opacity(0.15), radius: 8, x: 0, y: 4)
        ZStack(alignment: .leading) {
            // 背景のオーラ（余韻）
            Circle()
                .fill(
                    RadialGradient(
                        colors: [encounter.track.color.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 40)
                .offset(x: randomOffset * 3, y: randomOffset * 2)

            VStack(alignment: .leading, spacing: 0) {
                // メタ情報（時間）
                HStack {
                    Text(encounter.relativeTime.uppercased())
                        .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                        .kerning(2)
                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                    
                    Spacer()
                }
                .padding(.bottom, 8)

                // 巨大なユーザー名（Hero Typography）
                Text(encounter.userName)
                    .font(PrototypeTheme.Typography.font(size: 56, weight: .black, role: .primary))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .tracking(-2)
                    .lineLimit(1)
                    // 枠からはみ出るようなダイナミズム
                    .offset(x: -4) 

                // 楽曲情報（Glassmorphic Pill）
                HStack(spacing: 12) {
                    MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 32, artwork: encounter.track.artwork)
                        .clipShape(Circle())
                        .rotationEffect(.degrees(Double(randomOffset)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(encounter.track.title)
                            .font(PrototypeTheme.Typography.font(size: 14, weight: .bold))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                            .lineLimit(1)

                        Text(encounter.track.artist)
                            .font(PrototypeTheme.Typography.font(size: 11, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.trailing, 12)
                }
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                .offset(y: -12) // ユーザー名に少し被せる
                .padding(.bottom, 16)

                // 記憶の欠片（歌詞）
                if !encounter.lyric.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(encounter.track.color.opacity(0.4))
                            .offset(x: -8)

                        Text(encounter.lyric)
                            .font(PrototypeTheme.Typography.font(size: 20, weight: .medium, role: .accent))
                            .italic()
                            .foregroundStyle(PrototypeTheme.textPrimary.opacity(0.9))
                            .lineSpacing(6)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                }
            }
            .padding(32)
            // アシンメトリーな配置のためのオフセット
            .offset(x: randomOffset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // カードという枠を消し、空間に直接描画しているように見せる
        .background(Color.clear)
        .padding(.vertical, 24)
    }
}
