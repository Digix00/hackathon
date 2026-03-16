import SwiftUI

struct EncounterListView: View {
    private let sections = EncounterSection.allCases

    var body: some View {
        AppScaffold(
            title: "すれ違い",
            subtitle: "出会った音楽と相手の記録",
            trailingSymbol: "slider.horizontal.3"
        ) {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(sections) { section in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(section.rawValue)
                                .font(PrototypeTheme.Typography.Encounter.eyebrow)
                                .foregroundStyle(PrototypeTheme.textSecondary)

                            Spacer()

                            Rectangle()
                                .fill(PrototypeTheme.border.opacity(0.5))
                                .frame(height: 1)
                        }

                        VStack(spacing: 12) {
                            ForEach(MockData.encounters(in: section)) { encounter in
                                NavigationLink {
                                    EncounterDetailView(encounter: encounter)
                                } label: {
                                    EncounterRow(encounter: encounter)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}
