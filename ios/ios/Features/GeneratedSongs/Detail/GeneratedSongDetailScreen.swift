import AVFoundation
import Combine
import SwiftUI
import UIKit

struct GeneratedSongDetailView: View {
    let song: GeneratedSong
    @StateObject private var viewModel: GeneratedSongDetailViewModel
    @StateObject private var playerViewModel: GeneratedSongPlayerViewModel
    @State private var shareURL: URL?
    @State private var isShowingShareSheet = false

    init(song: GeneratedSong) {
        self.song = song
        _viewModel = StateObject(wrappedValue: GeneratedSongDetailViewModel(song: song))
        _playerViewModel = StateObject(wrappedValue: GeneratedSongPlayerViewModel(audioURLString: song.audioURL))
    }

    private var lyricEntries: [LyricEntryList.Row] {
        if !viewModel.lyricEntries.isEmpty {
            return viewModel.lyricEntries.map {
                LyricEntryList.Row(
                    id: $0.id,
                    content: $0.content,
                    userName: $0.userName,
                    sequenceNum: $0.sequenceNum
                )
            }
        }
        if let lyric = song.myLyric, !lyric.isEmpty {
            return [
                LyricEntryList.Row(
                    id: "my-lyric",
                    content: lyric,
                    userName: "あなた",
                    sequenceNum: 1
                )
            ]
        }
        return []
    }

    var body: some View {
        AppScaffold(
            title: song.title,
            subtitle: "\(song.participantCount)件のすれ違いから生成",
            showsBackButton: true,
            accentColor: song.color
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard {
                    VStack(spacing: 24) {
                        MockArtworkView(color: song.color, symbol: "waveform.and.magnifyingglass", size: 180)
                            .shadow(color: song.color.opacity(0.3), radius: 40, x: 0, y: 20)

                        VStack(spacing: 10) {
                            Text(song.title)
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .truncationMode(.tail)

                            Text(song.subtitle)
                                .prototypeFont(size: 15, weight: .bold, role: .data)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .multilineTextAlignment(.center)

                            metadataChips
                        }

                        playbackControls
                    }
                    .padding(.vertical, 12)
                }

                SectionCard(title: "参加した歌詞") {
                    VStack(alignment: .leading, spacing: 20) {
                        if viewModel.isLoadingLyrics {
                            ProgressView("読み込み中")
                        } else if lyricEntries.isEmpty {
                            Text("まだ歌詞が登録されていません")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        } else {
                            LyricEntryList(entries: lyricEntries)
                        }

                        if let lyricsErrorMessage = viewModel.lyricsErrorMessage {
                            Text(lyricsErrorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }
                    }
                }

                if let errorMessage = currentErrorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: "共有", systemImage: "square.and.arrow.up") {
                        if let audioURL = song.audioURL.flatMap(URL.init(string:)) {
                            shareURL = audioURL
                            isShowingShareSheet = true
                        }
                    }
                    .disabled(song.audioURL == nil)
                    .opacity(song.audioURL == nil ? 0.6 : 1.0)

                    SecondaryButton(
                        title: viewModel.isLiked ? "保存済み" : "保存",
                        systemImage: viewModel.isLiked ? "heart.fill" : "heart"
                    ) {
                        viewModel.toggleLike()
                    }
                    .disabled(viewModel.isProcessingLike)
                    .opacity(viewModel.isProcessingLike ? 0.6 : 1.0)
                }
            }
        }
        .task {
            viewModel.loadLyricsIfNeeded()
            playerViewModel.prepareIfNeeded()
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
        .onDisappear {
            playerViewModel.stop()
        }
    }

    private var metadataChips: some View {
        HStack(spacing: 10) {
            if let durationText = durationText {
                metadataChip(title: durationText, systemImage: "timer")
            }
            if let moodText = moodText {
                metadataChip(title: moodText, systemImage: "sparkles")
            }
        }
    }

    private func metadataChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(PrototypeTheme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(PrototypeTheme.surfaceMuted)
        .clipShape(Capsule())
    }

    private var playbackControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button {
                    playerViewModel.skip(by: -5)
                } label: {
                    playbackButtonLabel("gobackward.5")
                }
                .disabled(!playerViewModel.canPlay)

                Button {
                    playerViewModel.togglePlayback()
                } label: {
                    playbackButtonLabel(playerViewModel.isPlaying ? "pause.fill" : "play.fill", size: 26)
                }
                .disabled(!playerViewModel.canPlay)

                Button {
                    playerViewModel.skip(by: 5)
                } label: {
                    playbackButtonLabel("goforward.5")
                }
                .disabled(!playerViewModel.canPlay)
            }

            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { playerViewModel.progress },
                        set: { playerViewModel.seek(to: $0) }
                    ),
                    in: 0...1
                )
                .tint(song.color)
                .disabled(!playerViewModel.canPlay)

                HStack {
                    Text(playerViewModel.currentTimeText)
                    Spacer()
                    Text(playerViewModel.durationText)
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(PrototypeTheme.textSecondary)
            }

            if !playerViewModel.canPlay {
                Text("音源の準備ができるとここから再生できます。")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
        }
    }

    private func playbackButtonLabel(_ systemImage: String, size: CGFloat = 20) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(playerViewModel.canPlay ? song.color : PrototypeTheme.textTertiary)
            .frame(width: 52, height: 52)
            .background(PrototypeTheme.surfaceMuted)
            .clipShape(Circle())
    }

    private var durationText: String? {
        guard let duration = viewModel.durationSec ?? song.durationSec else { return nil }
        return "\(duration)秒"
    }

    private var moodText: String? {
        guard let mood = viewModel.mood ?? song.mood else { return nil }
        return mood.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var currentErrorMessage: String? {
        playerViewModel.errorMessage ?? viewModel.errorMessage
    }
}

@MainActor
final class GeneratedSongPlayerViewModel: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var currentTimeText = "0:00"
    @Published private(set) var durationText = "--:--"
    @Published private(set) var errorMessage: String?

    let canPlay: Bool

    private let audioURLString: String?
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var hasPrepared = false
    private var durationSeconds: Double = 0

    init(audioURLString: String?) {
        self.audioURLString = audioURLString
        self.canPlay = (audioURLString?.isEmpty == false)
    }

    deinit {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }

    func prepareIfNeeded() {
        guard canPlay, !hasPrepared else { return }
        guard let audioURLString, let url = URL(string: audioURLString) else {
            errorMessage = "再生用の音源 URL が不正です"
            return
        }

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        hasPrepared = true
        observePlayer(player: player, item: item)
    }

    func togglePlayback() {
        guard let player, canPlay else { return }
        errorMessage = nil
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func stop() {
        player?.pause()
        isPlaying = false
    }

    func skip(by seconds: Double) {
        guard let player else { return }
        let current = player.currentTime().seconds
        let target = min(max(current + seconds, 0), max(durationSeconds, current + seconds))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    func seek(to progress: Double) {
        guard let player, durationSeconds > 0 else { return }
        let clamped = min(max(progress, 0), 1)
        let seconds = durationSeconds * clamped
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        self.progress = clamped
        currentTimeText = Self.timeString(seconds)
    }

    private func observePlayer(player: AVPlayer, item: AVPlayerItem) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            let current = time.seconds
            if self.durationSeconds > 0 {
                self.progress = min(max(current / self.durationSeconds, 0), 1)
            }
            self.currentTimeText = Self.timeString(current)
        }

        Task { @MainActor in
            do {
                let duration = try await item.asset.load(.duration)
                let seconds = duration.seconds
                if seconds.isFinite, seconds > 0 {
                    durationSeconds = seconds
                    durationText = Self.timeString(seconds)
                }
            } catch {
                errorMessage = "曲の長さを取得できませんでした"
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.isPlaying = false
            self?.progress = 0
            self?.currentTimeText = "0:00"
        }
    }

    private static func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, !seconds.isNaN else { return "--:--" }
        let total = max(Int(seconds.rounded(.down)), 0)
        return "\(total / 60):" + String(format: "%02d", total % 60)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
