import SwiftUI

struct TrackSelectionRow: View {
    let track: Track
    var showsActionIcon: Bool = true

    var body: some View {
        HStack(spacing: 20) {
            // Elevated Artwork with Soft Glow
            ZStack {
                Circle()
                    .fill(track.color.opacity(0.12))
                    .frame(width: 64, height: 64)
                    .blur(radius: 12)
                
                MockArtworkView(color: track.color, symbol: "music.note", size: 54, artwork: track.artwork)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: track.color.opacity(0.18), radius: 10, x: 0, y: 6)
            }

            VStack(alignment: .leading, spacing: 6) {
                // Secondary Meta Info
                HStack(spacing: 8) {
                    Text("TRACK // SPECIMEN")
                        .prototypeFont(size: 8, weight: .black, role: .data)
                        .foregroundStyle(track.color.opacity(0.7))
                        .kerning(1.2)
                    
                    Text("128 BPM")
                        .prototypeFont(size: 8, weight: .bold, role: .data)
                        .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(track.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .tracking(-0.3)
                        .lineLimit(1)
                    
                    Text(track.artist.uppercased())
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .kerning(0.8)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsActionIcon {
                VStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(PrototypeTheme.accent.opacity(0.12))
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(PrototypeTheme.surface)
                .shadow(color: Color.black.opacity(0.015), radius: 12, x: 0, y: 8)
        )
    }
}
