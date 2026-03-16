import SwiftUI

struct EncounterRow: View {
    let encounter: Encounter

    var body: some View {
        HStack(spacing: 16) {
            MockArtworkView(color: encounter.track.color, symbol: "music.note", size: 52)
                .shadow(color: encounter.track.color.opacity(0.15), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(encounter.track.title)
                    .font(PrototypeTheme.Typography.Encounter.cardTitle)
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .lineLimit(1)

                Text(encounter.track.artist)
                    .font(PrototypeTheme.Typography.Encounter.body)
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(encounter.userName)
                    .font(PrototypeTheme.Typography.Encounter.meta)
                    .bold()
                    .foregroundStyle(PrototypeTheme.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(encounter.relativeTime)
                        .prototypeFont(size: 11, weight: .medium, role: .data)
                }
                .foregroundStyle(PrototypeTheme.textTertiary)
            }
        }
        .padding(16)
        .background(PrototypeTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
