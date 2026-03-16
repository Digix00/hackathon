import SwiftUI

struct EncounterSettingsView: View {
    var body: some View {
        AppScaffold(
            title: "すれ違い設定",
            subtitle: "検知範囲と公開設定"
        ) {
            VStack(spacing: 24) {
                SectionCard(title: "検知範囲") {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("半径")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Text("30m")
                                .prototypeFont(size: 16, weight: .black, role: .data)
                                .foregroundStyle(PrototypeTheme.accent)
                        }
                        
                        Slider(value: .constant(0.6))
                            .tint(PrototypeTheme.accent)
                    }
                }
                
                SectionCard {
                    Toggle(isOn: .constant(true)) {
                        Text("相手から見つけやすくする")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .tint(PrototypeTheme.success)
                }
            }
        }
    }
}

