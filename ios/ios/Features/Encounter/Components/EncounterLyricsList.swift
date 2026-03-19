import SwiftUI

struct EncounterLyricsList: View {
    let encounters: [Encounter]
    var waitingLine: String? = nil

    var body: some View {
        ForEach(Array(encounters.enumerated()), id: \.element.id) { index, encounter in
            VStack(alignment: .leading, spacing: 4) {
                Text("\(index + 1). \(encounter.lyric)")
                    .font(.system(size: 15, weight: .medium))
                Text(encounter.userName)
                    .font(.system(size: 12))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
        }

        if let waitingLine {
            Text(waitingLine)
                .font(.system(size: 15))
                .foregroundStyle(PrototypeTheme.textTertiary)
                .padding(.top, 4)
        }
    }
}
