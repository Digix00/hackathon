import SwiftUI

struct TrackSelectionRow: View {
    let track: Track

    var body: some View {
        HStack(spacing: 16) {
            MockArtworkView(color: track.color, symbol: "music.note", size: 52)
                .shadow(color: track.color.opacity(0.15), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(track.artist)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PrototypeTheme.textTertiary)
        }
    }
}
