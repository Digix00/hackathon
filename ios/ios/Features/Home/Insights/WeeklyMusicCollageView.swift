import SwiftUI

struct WeeklyMusicCollageView: View {
    let tracks: [Track]

    private var visibleTracks: [Track] { Array(tracks.prefix(6)) }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -12) { // Negative spacing for overlap
                ForEach(Array(visibleTracks.enumerated()), id: \.offset) { index, track in
                    NavigationLink {
                        EncounterListView()
                    } label: {
                        MockArtworkView(color: track.color, symbol: "music.note", size: 100, artwork: track.artwork)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                            .rotationEffect(.degrees(rotation(for: index)))
                            .offset(y: offset(for: index))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .zIndex(Double(visibleTracks.count - index))
                }

                if tracks.count > visibleTracks.count {
                    NavigationLink {
                        EncounterListView()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(PrototypeTheme.surfaceElevated)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(PrototypeTheme.textSecondary.opacity(0.1), lineWidth: 1)
                                )
                            
                            VStack(spacing: 4) {
                                Text("+\(tracks.count - visibleTracks.count)")
                                    .font(PrototypeTheme.Typography.font(size: 20, weight: .black, role: .data))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                Text("MORE")
                                    .font(PrototypeTheme.Typography.font(size: 8, weight: .black, role: .data))
                                    .foregroundStyle(PrototypeTheme.textTertiary)
                            }
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.leading, 12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30) // Space for rotation and shadow
        }
        .padding(.horizontal, -20) // Bleed to edges
    }

    private func rotation(for index: Int) -> Double {
        let angles: [Double] = [-6, 4, -3, 5, -2, 3]
        return angles[index % angles.count]
    }

    private func offset(for index: Int) -> CGFloat {
        let offsets: [CGFloat] = [0, 8, -4, 12, -2, 6]
        return offsets[index % offsets.count]
    }
}
