import SwiftUI

struct WeeklyMusicCollageView: View {
    let tracks: [Track]

    private var visibleTracks: [Track] { Array(tracks.prefix(7)) }

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(60), spacing: 12), count: 4)

        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(visibleTracks) { track in
                NavigationLink {
                    EncounterListView()
                } label: {
                    MockArtworkView(color: track.color, symbol: "music.note", size: 60)
                }
                .buttonStyle(.plain)
            }

            if tracks.count > visibleTracks.count {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(PrototypeTheme.surfaceElevated)
                        .frame(width: 60, height: 60)
                    Text("+\(tracks.count - visibleTracks.count)")
                        .prototypeFont(size: 16, weight: .black, role: .data)
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }
            }
        }
    }
}
