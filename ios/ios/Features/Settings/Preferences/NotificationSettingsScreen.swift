import SwiftUI

struct NotificationSettingsView: View {
    @State private var encounterNotify = true
    @State private var lyricNotify = true

    var body: some View {
        AppScaffold(
            title: "通知設定",
            subtitle: "COMMS & ALERTS"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("ALERT PROTOCOLS")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Spacer()
                        Text("NTF-01")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                    }
                    .padding(.horizontal, 4)

                    GlassmorphicCard {
                        VStack(spacing: 0) {
                            toggleRow(
                                title: "すれ違い検知",
                                subtitle: "近くで誰かを見つけた時に通知",
                                code: "NTF-MATCH",
                                isOn: $encounterNotify
                            )
                            
                            Divider()
                                .background(PrototypeTheme.border.opacity(0.5))
                                .padding(.vertical, 16)
                            
                            toggleRow(
                                title: "歌詞チェーン生成",
                                subtitle: "参加した楽曲が完成した時に通知",
                                code: "NTF-GEN-COMPLETE",
                                isOn: $lyricNotify
                            )
                        }
                    }
                }

                // --- FOOTER DESCRIPTION ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(PrototypeTheme.accent)
                        Text("SYSTEM BROADCAST")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                    
                    Text("通知をオフにしても、アプリ内の交換履歴はリアルタイムで更新されます。楽曲の生成完了は重要なイベントのため、オンにすることをお勧めします。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(PrototypeTheme.surfaceMuted.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func toggleRow(title: String, subtitle: String, code: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                    
                    Text(code)
                        .prototypeFont(size: 8, weight: .black, role: .data)
                        .foregroundStyle(PrototypeTheme.accent.opacity(0.5))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(PrototypeTheme.accent.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(PrototypeTheme.accent)
                .labelsHidden()
        }
    }
}
