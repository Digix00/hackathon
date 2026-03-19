import SwiftUI

struct ChainProgressView: View {
    @StateObject private var viewModel: ChainProgressViewModel

    init(chainId: String?) {
        _viewModel = StateObject(wrappedValue: ChainProgressViewModel(chainId: chainId))
    }

    var body: some View {
        AppScaffold(
            title: "歌詞チェーン",
            subtitle: viewModel.statusTitle
        ) {
            VStack(alignment: .leading, spacing: 28) {
                if viewModel.isLoading && viewModel.chain == nil {
                    ProgressView("読み込み中")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let chain = viewModel.chain {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack(spacing: 12) {
                                ForEach(0..<max(chain.threshold, 1), id: \.self) { index in
                                    Circle()
                                        .fill(index < chain.participantCount ? PrototypeTheme.accent : PrototypeTheme.border)
                                        .frame(width: 14, height: 14)
                                }
                            }

                        let status = chain.status.lowercased()
                        let isPending = status == "pending"
                        let isRecruiting = isPending && chain.participantCount < chain.threshold

                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.progressText)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(PrototypeTheme.textSecondary)

                            Text(status == "completed"
                                ? "歌詞が揃いました。"
                                : isPending
                                    ? "あと\(max(chain.threshold - chain.participantCount, 0))人で曲が完成します。"
                                    : status == "generating"
                                        ? "楽曲を生成中です。"
                                        : status == "failed"
                                            ? "楽曲生成に失敗しました。"
                                            : "歌詞を集めています。")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                        }
                    }
                    }

                    SectionCard(title: "集まった歌詞") {
                        VStack(alignment: .leading, spacing: 20) {
                            LyricEntryList(
                                entries: viewModel.entries.map {
                                    LyricEntryList.Row(
                                        id: $0.id,
                                        content: $0.content,
                                        userName: $0.userName,
                                        sequenceNum: $0.sequenceNum
                                    )
                                },
                                waitingLine: isRecruiting
                                    ? "\(chain.participantCount + 1). 最後のひとりを待っています..."
                                    : nil
                            )
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(viewModel.errorMessage ?? "歌詞チェーンが見つかりませんでした")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(PrototypeTheme.textSecondary)

                        SecondaryButton(title: "再読み込み", systemImage: "arrow.clockwise") {
                            viewModel.refresh()
                        }
                    }
                }
            }
        }
        .task {
            viewModel.loadIfNeeded()
        }
    }
}
