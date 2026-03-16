import SwiftUI

struct ChainProgressView: View {
    private let contributingEncounters = MockData.chainContributors

    var body: some View {
        AppScaffold(
            title: "歌詞チェーン",
            subtitle: "歌詞を集めています"
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 12) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(index < 3 ? PrototypeTheme.accent : PrototypeTheme.border)
                                    .frame(width: 14, height: 14)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("3/4人が参加")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            
                            Text("あと1人で曲が完成します。")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                        }
                    }
                }

                SectionCard(title: "集まった歌詞") {
                    VStack(alignment: .leading, spacing: 20) {
                        EncounterLyricsList(
                            encounters: contributingEncounters,
                            waitingLine: "4. 最後のひとりを待っています..."
                        )
                    }
                }
            }
        }
    }
}

