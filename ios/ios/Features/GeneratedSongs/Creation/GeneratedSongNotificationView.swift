import Combine
import SwiftUI

struct GeneratedSongNotificationView: View {
    let song: GeneratedSong
    var onListenNow: (() -> Void)? = nil
    var onLater: (() -> Void)? = nil

    @State private var isAnimating = false

    var body: some View {
        GeometryReader { proxy in
            let globalWidth = proxy.frame(in: .global).width
            let layoutWidth = globalWidth > 0 ? min(proxy.size.width, globalWidth) : proxy.size.width

            ZStack {
                DynamicBackground(baseColor: song.color)

                VStack(spacing: 32) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 200, height: 200)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .blur(radius: 30)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)

                        MockArtworkView(color: song.color, symbol: "sparkles", size: 120)
                            .shadow(color: song.color.opacity(0.8), radius: isAnimating ? 40 : 20, x: 0, y: 15)
                            .rotationEffect(.degrees(isAnimating ? 8 : -8))
                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .onAppear {
                        isAnimating = true
                    }

                    VStack(spacing: 16) {
                        Text("新しい曲が生まれました")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white.opacity(0.7))
                            .kerning(2.0)

                        Text("「\(song.title)」")
                            .font(.system(size: 36, weight: .black))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        Text("\(song.participantCount)人の出会いから生まれた曲です。")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    Spacer()

                    VStack(spacing: 16) {
                        PrimaryButton(title: "今すぐ聴く", systemImage: "play.fill", isDisabled: song.audioURL == nil) {
                            onListenNow?()
                        }

                        Button("あとで") {
                            onLater?()
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 32)
                }
                .padding(.vertical, 32)
                .frame(width: layoutWidth)
            }
            .frame(width: layoutWidth, height: proxy.size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .ignoresSafeArea()
    }
}

@MainActor
final class GeneratedSongNotificationLoaderViewModel: ObservableObject {
    @Published private(set) var song: GeneratedSong?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let client: BackendAPIClient
    private var hasLoaded = false

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
    }

    func loadIfNeeded() {
        guard !hasLoaded, !isLoading else { return }
        Task { await loadLatestSong() }
    }

    private func loadLatestSong() async {
        isLoading = true
        errorMessage = nil

        if MockData.forceGeneratedSongMocks {
            song = MockData.playableGeneratedSongs.first ?? MockData.generatedSongs.first
            hasLoaded = true
            errorMessage = "モックの生成曲を表示しています"
            isLoading = false
            return
        }

        do {
            let response = try await client.listMySongs()
            let items = response.songs
            let latest = items.max {
                ($0.generatedAt ?? .distantPast) < ($1.generatedAt ?? .distantPast)
            } ?? items.first

            if let latest {
                song = Self.mapSong(latest)
                hasLoaded = true
            } else {
                song = MockData.playableGeneratedSongs.first ?? MockData.generatedSongs.first
                hasLoaded = true
                errorMessage = "モックの生成曲を表示しています"
            }
        } catch {
            song = MockData.playableGeneratedSongs.first ?? MockData.generatedSongs.first
            hasLoaded = true
            errorMessage = "API に接続できないためモックの生成曲を表示しています"
        }

        isLoading = false
    }

    private static func mapSong(_ latest: BackendUserSong) -> GeneratedSong {
        let title = latest.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        return GeneratedSong(
            id: latest.id,
            title: title?.isEmpty == false ? title! : "無題の曲",
            subtitle: "\(max(0, latest.participantCount))人で作成",
            color: .indigo,
            participantCount: max(0, latest.participantCount),
            generatedAt: latest.generatedAt,
            durationSec: latest.durationSec,
            mood: latest.mood,
            myLyric: latest.myLyric.isEmpty ? nil : latest.myLyric,
            audioURL: latest.audioURL,
            chainId: latest.chainId,
            isLiked: latest.liked ?? false
        )
    }
}

struct GeneratedSongNotificationLoaderView: View {
    @StateObject private var viewModel = GeneratedSongNotificationLoaderViewModel()
    let onDismiss: () -> Void
    let onListenNow: (GeneratedSong) -> Void

    var body: some View {
        ZStack {
            if let song = viewModel.song {
                GeneratedSongNotificationView(
                    song: song,
                    onListenNow: { onListenNow(song) },
                    onLater: onDismiss
                )
            } else if viewModel.isLoading {
                ProgressView("生成曲を読み込み中")
                    .foregroundStyle(PrototypeTheme.textPrimary)
            } else {
                VStack(spacing: 16) {
                    Text(viewModel.errorMessage ?? "表示できる生成曲がありません")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textPrimary)

                    SecondaryButton(title: "閉じる", systemImage: "xmark") {
                        onDismiss()
                    }
                }
                .padding(24)
            }
        }
        .task {
            viewModel.loadIfNeeded()
        }
    }
}
