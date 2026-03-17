import SwiftUI

struct EncounterListView: View {
    private var encounters: [Encounter] {
        EncounterSection.allCases.flatMap { MockData.encounters(in: $0) }
    }

    var body: some View {
        AppScaffold(
            title: "つながり",
            subtitle: "都市のノイズが生んだ、一期一会の旋律",
            trailingSymbol: "slider.horizontal.3"
        ) {
            VStack(alignment: .leading, spacing: 100) {
                LazyVStack(spacing: 80) {
                    ForEach(Array(encounters.enumerated()), id: \.offset) { index, encounter in
                        NavigationLink {
                            EncounterDetailView(encounter: encounter)
                        } label: {
                            EncounterRow(encounter: encounter, isFixed: index == 0)
                        }
                        .buttonStyle(EncounterScaleButtonStyle())
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
