import SwiftUI

struct GeneratingStateView: View {
    var body: some View {
        AppScaffold(
            title: "生成状態",
            subtitle: "AI作曲の進行状況"
        ) {
            VStack(spacing: 24) {
                SectionCard(title: "生成中") {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Label("歌詞を編集中", systemImage: "waveform.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Text("65%")
                                .prototypeFont(size: 14, weight: .black, role: .data)
                        }
                        .foregroundStyle(PrototypeTheme.accent)
                        
                        ProgressView(value: 0.65)
                            .tint(PrototypeTheme.accent)
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                        
                        Text("4人の歌詞をまとめて1曲にしています。")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .lineSpacing(4)
                    }
                }

                SectionCard(title: "エラー") {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("接続が中断されました", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(PrototypeTheme.error)
                        
                        Text("AIサーバーへの接続に失敗しました。")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        
                        SecondaryButton(title: "再試行", systemImage: "arrow.clockwise") {}
                    }
                }
            }
        }
    }
}

