import SwiftUI

struct ChainProgressView: View {
    @StateObject private var viewModel: ChainProgressViewModel
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator
    @Environment(\.dismiss) private var dismiss

    init(chainId: String?) {
        _viewModel = StateObject(wrappedValue: ChainProgressViewModel(chainId: chainId))
    }

    var body: some View {
        ZStack {
            DynamicBackground(baseColor: .indigo)
            
            if viewModel.isLoading && viewModel.chain == nil {
                ProgressView("接続中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let chain = viewModel.chain {
                content(chain: chain)
            } else {
                errorState
            }
        }
        .navigationBarBackButtonHidden()
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(PrototypeTheme.surface.opacity(0.8)))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .task {
            viewModel.loadIfNeeded()
        }
    }

    private func content(chain: BackendChainDetail) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 40) {
                progressHero(chain: chain)
                    .padding(.top, 60)

                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("COLLECTED FRAGMENTS")
                            .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                            .kerning(2)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(PrototypeTheme.border)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 32)

                    LyricEntryList(
                        entries: lyricRows(for: chain),
                        waitingLine: waitingLine(for: chain)
                    )
                    .padding(.horizontal, 16)
                }

                if chain.status.lowercased() == "completed", let song = viewModel.song {
                    NavigationLink {
                        GeneratedSongDetailView(song: generatedSong(from: song, chain: chain))
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                            Text("完成した曲を聴く")
                                .font(PrototypeTheme.Typography.font(size: 16, weight: .black))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 18)
                        .background(Capsule().fill(Color.indigo).shadow(color: Color.indigo.opacity(0.3), radius: 20, y: 10))
                    }
                    .padding(.bottom, 40)
                }
                
                Spacer(minLength: 100)
            }
        }
    }

    private func progressHero(chain: BackendChainDetail) -> some View {
        let status = chain.status.lowercased()
        let remainingParticipants = max(chain.threshold - chain.participantCount, 0)
        let progress = CGFloat(chain.participantCount) / CGFloat(max(chain.threshold, 1))

        return VStack(spacing: 32) {
            // Visual Progress Core
            ZStack {
                Circle()
                    .stroke(Color.indigo.opacity(0.1), lineWidth: 12)
                    .frame(width: 180, height: 180)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [.indigo, .indigo.opacity(0.6), .indigo],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.2, dampingFraction: 0.8), value: progress)
                
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 44, weight: .black, design: .monospaced))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                    
                    Text("\(chain.participantCount) / \(chain.threshold)")
                        .font(PrototypeTheme.Typography.font(size: 12, weight: .black, role: .data))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }
            }

            // Status Text
            VStack(spacing: 12) {
                Text(viewModel.statusTitle.uppercased())
                    .font(PrototypeTheme.Typography.font(size: 12, weight: .black, role: .data))
                    .foregroundStyle(Color.indigo)
                    .kerning(2)

                Text(status == "completed" ? "共鳴が完了しました" : (remainingParticipants > 0 ? "あと\(remainingParticipants)人の共鳴で曲が生まれます" : "曲を生成しています..."))
                    .font(PrototypeTheme.Typography.font(size: 24, weight: .black))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    private var errorState: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(PrototypeTheme.error)
            
            Text(viewModel.errorMessage ?? "チェーンの情報を取得できませんでした")
                .font(PrototypeTheme.Typography.font(size: 16, weight: .bold))
                .foregroundStyle(PrototypeTheme.textPrimary)
            
            SecondaryButton(title: "再読み込み", systemImage: "arrow.clockwise") {
                viewModel.refresh()
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
            ? "\(chain.participantCount + 1). 最後の共鳴を待っています..."
            : "\(chain.participantCount + 1). あと\(remainingParticipants)人の共鳴を待っています..."
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
}

