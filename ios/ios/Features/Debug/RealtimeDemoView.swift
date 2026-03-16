import SwiftUI

struct RealtimeDemoView: View {
    @State private var scenario: RealtimeScenario = .standby

    var body: some View {
        AppScaffold(
            title: "リアルタイム演出",
            subtitle: "状態変化の見え方を確認"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                Picker("状態", selection: $scenario) {
                    ForEach(RealtimeScenario.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                SectionCard {
                    VStack(spacing: 28) {
                        ZStack {
                            Circle()
                                .fill(PrototypeTheme.surfaceElevated)
                                .frame(width: 180, height: 180)
                            
                            Circle()
                                .fill(circleColor.opacity(0.15))
                                .frame(width: circleSize + 20, height: circleSize + 20)
                            
                            MockArtworkView(color: circleColor, symbol: "music.note", size: 90)
                                .shadow(color: circleColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        }
                        
                        VStack(spacing: 12) {
                            Text(statusTitle)
                                .font(.system(size: 24, weight: .black))
                            
                            Text(statusMessage)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var circleColor: Color {
        switch scenario {
        case .standby: return .gray
        case .approaching: return .yellow
        case .matched: return .green
        case .afterglow: return .indigo
        }
    }

    private var circleSize: CGFloat {
        switch scenario {
        case .standby: return 120
        case .approaching: return 140
        case .matched: return 160
        case .afterglow: return 130
        }
    }

    private var statusTitle: String {
        switch scenario {
        case .standby: return "検知を待っています"
        case .approaching: return "反応を検知しました"
        case .matched: return "すれ違いが成立しました"
        case .afterglow: return "余韻を表示しています"
        }
    }

    private var statusMessage: String {
        switch scenario {
        case .standby: return "近くのビーコンを探しています。"
        case .approaching: return "近くに誰かがいます。"
        case .matched: return "歌詞の断片を受け取りました。"
        case .afterglow: return "出会いの余韻を穏やかに見せます。"
        }
    }
}

