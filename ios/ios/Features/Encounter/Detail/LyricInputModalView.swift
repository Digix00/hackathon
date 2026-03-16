import SwiftUI
import UIKit

struct LyricInputModalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var lyric = "今日も空は青かった"
    @State private var didTriggerNearLimitHaptic = false

    var body: some View {
        NavigationStack {
            ZStack {
                PrototypeTheme.background.ignoresSafeArea()
                
                // Subtle blur background accent
                Circle()
                    .fill(PrototypeTheme.accent.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: 100, y: -200)

                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("この出会いを残す")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(PrototypeTheme.accent)
                            .kerning(2.0)
                        
                        Text("この出会いに一言")
                            .font(.system(size: 32, weight: .black))
                    }
                    
                    VStack(spacing: 12) {
                        TextEditor(text: $lyric)
                            .scrollContentBackground(.hidden)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(PrototypeTheme.surface.opacity(0.8))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .frame(height: 160)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                            .onChange(of: lyric) { newValue in
                                let isNearLimit = newValue.count >= 90
                                if isNearLimit && !didTriggerNearLimitHaptic {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    didTriggerNearLimitHaptic = true
                                } else if !isNearLimit {
                                    didTriggerNearLimitHaptic = false
                                }
                            }
                        
                        HStack {
                            Spacer()
                            Text("\(lyric.count)/100")
                                .prototypeFont(size: 12, weight: .bold, role: .data)
                                .foregroundStyle(lyric.count > 90 ? PrototypeTheme.error : PrototypeTheme.textTertiary)
                        }
                    }

                    Text("この言葉はAI生成曲の一部になります。")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)

                    VStack(spacing: 16) {
                        PrimaryButton(title: "歌詞を送信", systemImage: "paperplane.fill", isDisabled: lyric.isEmpty) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            dismiss()
                        }
                        
                        Button("今はスキップ") {
                            dismiss()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                    }

                    Spacer()
                }
                .padding(28)
            }
        }
        .presentationDetents([.large])
    }
}

