import SwiftUI

struct ChainProgressView: View {
    @StateObject private var viewModel: ChainProgressViewModel
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator

    init(chainId: String?) {
        _viewModel = StateObject(wrappedValue: ChainProgressViewModel(chainId: chainId))
    }

    var body: some View {
        AppScaffold(
            title: "歌詞チェーン",
            subtitle: viewModel.statusTitle,
            showsBackButton: true
        ) {
            VStack(alignment: .leading, spacing: 28) {
                if viewModel.isLoading && viewModel.chain == nil {
                    ProgressView("読み込み中")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let chain = viewModel.chain {
                    progressHero(chain: chain)
                    SectionCard(title: "集まった歌詞") {
                        LyricEntryList(
                            entries: lyricRows(for: chain),
                            waitingLine: waitingLine(for: chain)
                        )
                    }

                    if chain.status.lowercased() == "completed", let song = viewModel.song {
                        NavigationLink {
                            GeneratedSongDetailView(song: generatedSong(from: song, chain: chain))
                        } label: {
                            SecondaryButtonLabel(title: "曲を聴く", systemImage: "play.circle.fill")
                        }
                        .buttonStyle(.plain)
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

    private func progressHero(chain: BackendChainDetail) -> some View {
        let status = chain.status.lowercased()
        let remainingParticipants = max(chain.threshold - chain.participantCount, 0)

        return SectionCard {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    ForEach(0..<max(chain.threshold, 1), id: \.self) { index in
                        Circle()
                            .fill(fillColor(for: index, chain: chain))
                            .frame(width: 14, height: 14)
                            .overlay {
                                if isMyLyricSlot(index: index, chain: chain) {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .padding(1)
                                }
                            }
                    }
                }

                switch status {
                case "completed":
                    completedState
                case "generating":
                    generatingState
                case "failed":
                    failedState
                default:
                    pendingState(
                        progressText: viewModel.progressText,
                        remainingParticipants: remainingParticipants
                    )
                }
            }
        }
    }

    private var completedState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("歌詞がそろいました", systemImage: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PrototypeTheme.accent)

            Text("完成した曲を確認できます。")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(PrototypeTheme.textPrimary)

            if let song = viewModel.song?.title, !song.isEmpty {
                Text(song)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
        }
    }

    private var generatingState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("生成中", systemImage: "waveform.badge.magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PrototypeTheme.accent)

            Text("曲を作成しています。")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(PrototypeTheme.textPrimary)

            Text("完成したら通知でお知らせします。")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)
        }
    }

    private var failedState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("生成失敗", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PrototypeTheme.error)

            Text("曲の生成に失敗しました。")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(PrototypeTheme.textPrimary)

            Text("技術的な問題が発生しました。時間をおいて再度確認してください。")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)
        }
    }

    private func pendingState(progressText: String, remainingParticipants: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(progressText)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(PrototypeTheme.textSecondary)

            Text(remainingParticipants > 0
                ? "あと\(remainingParticipants)人で曲が完成します。"
                : "歌詞がそろいました。")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(PrototypeTheme.textPrimary)

            if let content = currentUserLyricContent {
                Text("あなたの歌詞: “\(content)”")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
        }
    }

    private func lyricRows(for chain: BackendChainDetail) -> [LyricEntryList.Row] {
        viewModel.entries.map { entry in
            let isMine = currentUserLyricContent == entry.content && chain.id == bleCoordinator.latestLyricSubmission?.chain.id
            return LyricEntryList.Row(
                id: entry.id,
                content: entry.content,
                userName: isMine ? "あなた" : entry.userName,
                sequenceNum: entry.sequenceNum
            )
        }
    }

    private func waitingLine(for chain: BackendChainDetail) -> String? {
        let status = chain.status.lowercased()
        let remainingParticipants = max(chain.threshold - chain.participantCount, 0)
        guard status == "pending", remainingParticipants > 0 else { return nil }
        return remainingParticipants == 1
            ? "\(chain.participantCount + 1). 最後のひとりを待っています..."
            : "\(chain.participantCount + 1). あと\(remainingParticipants)人を待っています..."
    }

    private func generatedSong(from song: BackendSongDetail, chain: BackendChainDetail) -> GeneratedSong {
        let title = song.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeTitle = title?.isEmpty == false ? title! : "無題の曲"
        return GeneratedSong(
            id: song.id,
            title: safeTitle,
            subtitle: "\(chain.participantCount)人で作成",
            color: .indigo,
            participantCount: chain.participantCount,
            generatedAt: chain.completedAt,
            durationSec: song.durationSec,
            mood: song.mood,
            myLyric: currentUserLyricContent,
            audioURL: song.audioURL,
            chainId: chain.id,
            isLiked: false
        )
    }

    private var currentUserLyricContent: String? {
        guard let submission = bleCoordinator.latestLyricSubmission,
              submission.chain.id == viewModel.chain?.id else {
            return nil
        }
        return submission.content
    }

    private func isMyLyricSlot(index: Int, chain: BackendChainDetail) -> Bool {
        guard let content = currentUserLyricContent else { return false }
        guard let myEntry = viewModel.entries.first(where: { $0.content == content }) else { return false }
        return myEntry.sequenceNum == index + 1
    }

    private func fillColor(for index: Int, chain: BackendChainDetail) -> Color {
        if isMyLyricSlot(index: index, chain: chain) {
            return PrototypeTheme.accent
        }
        return index < chain.participantCount ? PrototypeTheme.textPrimary : PrototypeTheme.border
    }
}
