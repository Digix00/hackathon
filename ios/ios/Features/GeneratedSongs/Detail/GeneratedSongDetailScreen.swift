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
    @State private var showContent = false
    @Environment(\.encounterNamespace) private var namespace
    @Environment(\.dismiss) private var dismiss

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
        GeometryReader { proxy in
            let globalWidth = proxy.frame(in: .global).width
            let layoutWidth = globalWidth > 0 ? min(proxy.size.width, globalWidth) : proxy.size.width
            let horizontalPadding: CGFloat = layoutWidth < 390 ? 20 : 32
            let readableWidth = max(layoutWidth - (horizontalPadding * 2), 0)
            let sectionWidth = min(readableWidth, 560)
            
            ZStack {
                // Background
                PrototypeTheme.background.ignoresSafeArea()
                
                // Morphing Aura
                morphingAura
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Section
                        VStack(spacing: showContent ? 48 : 32) {
                            // Artwork
                            ZStack {
                                if let namespace = namespace {
                                    MockArtworkView(color: song.color, symbol: "waveform", size: showContent ? 240 : 84)
                                        .matchedGeometryEffect(id: "song-artwork-\(song.id)", in: namespace)
                                } else {
                                    MockArtworkView(color: song.color, symbol: "waveform", size: 240)
                                }
                            }
                            .shadow(color: song.color.opacity(showContent ? 0.2 : 0.1), radius: showContent ? 60 : 20, x: 0, y: 30)
                            .padding(.top, showContent ? 60 : 100)

                            // Titles
                            VStack(spacing: 12) {
                                if let namespace = namespace {
                                    Text(song.title)
                                        .font(PrototypeTheme.Typography.font(size: showContent ? 36 : 32, weight: .black))
                                        .matchedGeometryEffect(id: "song-title-\(song.id)", in: namespace)
                                        .multilineTextAlignment(.center)
                                } else {
                                    Text(song.title)
                                        .font(PrototypeTheme.Typography.font(size: 36, weight: .black))
                                }

                                if let namespace = namespace {
                                    Text(song.subtitle)
                                        .font(PrototypeTheme.Typography.font(size: 16, weight: .bold, role: .accent))
                                        .foregroundStyle(song.color)
                                        .matchedGeometryEffect(id: "song-subtitle-\(song.id)", in: namespace)
                                } else {
                                    Text(song.subtitle)
                                        .font(PrototypeTheme.Typography.font(size: 16, weight: .bold, role: .accent))
                                        .foregroundStyle(song.color)
                                }
                            }
                            .frame(maxWidth: sectionWidth)

                            if showContent {
                                playbackControls
                                    .frame(maxWidth: sectionWidth)
                                    .transition(.opacity.combined(with: .offset(y: 20)))
                            }
                        }
                        .frame(maxWidth: .infinity)

                        if showContent {
                            // Lyrics Section
                            VStack(alignment: .leading, spacing: 24) {
                                HStack {
                                    Text("SHARED LYRICS")
                                        .font(PrototypeTheme.Typography.font(size: 12, weight: .black, role: .data))
                                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                                        .kerning(2)
                                    
                                    Spacer()
                                    
                                    Rectangle()
                                        .fill(PrototypeTheme.border)
                                        .frame(height: 1)
                                }

                                if viewModel.isLoadingLyrics {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 40)
                                } else if lyricEntries.isEmpty {
                                    Text("歌詞の断片を読み込めませんでした")
                                        .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                                        .foregroundStyle(PrototypeTheme.textTertiary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 40)
                                } else {
                                    LyricEntryList(entries: lyricEntries)
                                        .padding(.horizontal, 8)
                                }
                            }
                            .frame(maxWidth: sectionWidth)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                            .transition(.opacity.combined(with: .offset(y: 30)))
                            
                            // Actions
                            HStack(spacing: 16) {
                                SecondaryButton(title: "共有", systemImage: "square.and.arrow.up") {
                                    if let audioURL = song.audioURL.flatMap(URL.init(string:)) {
                                        shareURL = audioURL
                                        isShowingShareSheet = true
                                    }
                                }
                                .disabled(song.audioURL == nil)

                                SecondaryButton(
                                    title: viewModel.isLiked ? "保存済み" : "保存",
                                    systemImage: viewModel.isLiked ? "heart.fill" : "heart"
                                ) {
                                    viewModel.toggleLike()
                                }
                                .disabled(viewModel.isProcessingLike)
                            }
                            .frame(maxWidth: sectionWidth)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 32)
                            .transition(.opacity.combined(with: .offset(y: 40)))
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .frame(width: layoutWidth)
                }
                .frame(width: layoutWidth)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(width: layoutWidth, height: proxy.size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .navigationBarBackButtonHidden()
            .safeAreaInset(edge: .top) {
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showContent = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            dismiss()
                        }
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
                .frame(width: layoutWidth)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
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

    private var morphingAura: some View {
        ZStack {
            LinearGradient(
                colors: [
                    song.color.opacity(showContent ? 0.15 : 0.0),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            song.color.opacity(0.2),
                            song.color.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: showContent ? 300 : 150
                    )
                )
                .frame(width: showContent ? 600 : 300, height: showContent ? 600 : 300)
                .blur(radius: showContent ? 100 : 50)
                .offset(y: showContent ? -150 : 0)
        }
    }

    private var playbackControls: some View {
        VStack(spacing: 24) {
            // Progress Slider
            VStack(spacing: 12) {
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
                .font(PrototypeTheme.Typography.font(size: 12, weight: .black, role: .data))
                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
            }

            // Buttons
            HStack(spacing: 40) {
                Button {
                    playerViewModel.skip(by: -5)
                } label: {
                    Image(systemName: "gobackward.5")
                        .font(.system(size: 24, weight: .medium))
                }
                .disabled(!playerViewModel.canPlay)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    playerViewModel.togglePlayback()
                } label: {
                    ZStack {
                        Circle()
                            .fill(song.color)
                            .frame(width: 80, height: 80)
                            .shadow(color: song.color.opacity(0.3), radius: 20, y: 10)
                        
                        Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .disabled(!playerViewModel.canPlay)
                .scaleEffect(playerViewModel.isPlaying ? 0.95 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: playerViewModel.isPlaying)

                Button {
                    playerViewModel.skip(by: 5)
                } label: {
                    Image(systemName: "goforward.5")
                        .font(.system(size: 24, weight: .medium))
                }
                .disabled(!playerViewModel.canPlay)
            }
            .foregroundStyle(playerViewModel.canPlay ? PrototypeTheme.textPrimary : PrototypeTheme.textTertiary)

            if !playerViewModel.canPlay {
                Text("音源を生成中です...")
                    .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .italic()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(PrototypeTheme.surface.opacity(0.4))
                .background(Blur(style: .systemThinMaterialLight).opacity(0.2))
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}

struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
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
