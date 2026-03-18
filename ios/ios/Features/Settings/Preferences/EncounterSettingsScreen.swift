import SwiftUI

struct EncounterSettingsView: View {
    @State private var radius: Double = 30.0

    var body: some View {
        AppScaffold(
            title: "すれ違い設定",
            subtitle: "PROXIMITY PROTOCOL"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                
                // --- RADIUS CONFIG ---
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("DETECTION RADIUS")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Spacer()
                        Text("PRM-DIST")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                    }
                    .padding(.horizontal, 4)

                    GlassmorphicCard {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack {
                                Text("有効半径")
                                    .font(.system(size: 17, weight: .bold))
                                Spacer()
                                Text("\(Int(radius))m")
                                    .prototypeFont(size: 20, weight: .black, role: .data)
                                    .foregroundStyle(PrototypeTheme.accent)
                            }
                            
                            Slider(value: $radius, in: 5...100, step: 5)
                                .tint(PrototypeTheme.accent)
                            
                            HStack {
                                Text("MIN: 5m")
                                    .prototypeFont(size: 9, weight: .bold, role: .data)
                                Spacer()
                                Text("MAX: 100m")
                                    .prototypeFont(size: 9, weight: .bold, role: .data)
                            }
                            .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                    }
                }

                // --- VISIBILITY CONFIG ---
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("BROADCAST STATUS")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Spacer()
                        Text("PRM-VIS")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                    }
                    .padding(.horizontal, 4)

                    SectionCard {
                        Toggle(isOn: .constant(true)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("公開モード")
                                    .font(.system(size: 17, weight: .bold))
                                Text("周囲のデバイスから検知可能になります")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                        }
                        .tint(PrototypeTheme.success)
                        .padding(.vertical, 4)
                    }
                }

                // --- DIAGNOSTIC FOOTER ---
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(PrototypeTheme.success)
                            .frame(width: 6, height: 6)
                        Text("REAL-TIME CALIBRATION")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }
                    
                    Text("現在、あなたのデバイスは半径 \(Int(radius))m 以内の BLE ビーコンをスキャンし、自身のシグナルを送信しています。精度は環境（遮蔽物、電波干渉）によって変動します。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(PrototypeTheme.surfaceMuted.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 20)
            }
        }
    }
}
