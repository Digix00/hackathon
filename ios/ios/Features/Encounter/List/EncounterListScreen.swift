import SwiftUI

struct EncounterListView: View {
    private let sections = EncounterSection.allCases

    var body: some View {
        AppScaffold(
            title: "つながり",
            subtitle: "都市のノイズが生んだ、一期一会の旋律",
            trailingSymbol: "slider.horizontal.3"
        ) {
            VStack(alignment: .leading, spacing: 100) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 0) {
                        // Section Header: ドットを削除し、純粋な空間に
                        HStack(alignment: .center, spacing: 12) {
                            Text(section.rawValue)
                                .font(PrototypeTheme.Typography.font(size: 11, weight: .black, role: .data))
                                .kerning(4)
                                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.3))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 48)

                        VStack(spacing: 80) {
                            // セクション内の要素を取得
                            let encounters = MockData.encounters(in: section)
                            
                            ForEach(0..<encounters.count, id: \.self) { index in
                                let encounter = encounters[index]
                                // 最初のセクションの最初の要素だけを「固定（Hero）」にする
                                let isHero = (section == .today && index == 0)
                                
                                NavigationLink {
                                    EncounterDetailView(encounter: encounter)
                                } label: {
                                    EncounterRow(encounter: encounter, isFixed: isHero)
                                }
                                .buttonStyle(EncounterScaleButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 160)
        }
    }
}

struct EncounterScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
