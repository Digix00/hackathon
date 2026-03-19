import SwiftUI

struct LyricEntryList: View {
    struct Row: Identifiable, Equatable {
        let id: String
        let content: String
        let userName: String
        let sequenceNum: Int
    }

    let entries: [Row]
    var waitingLine: String? = nil

    var body: some View {
        ForEach(entries) { entry in
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.sequenceNum). \(entry.content)")
                    .font(.system(size: 15, weight: .medium))
                Text(entry.userName)
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
