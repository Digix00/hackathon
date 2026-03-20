import SwiftUI

struct GeneratedSongsView: View {
    @StateObject private var viewModel = GeneratedSongsViewModel()
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator
    @State private var celebrationSong: GeneratedSong?
    @State private var selectedSong: GeneratedSong?
    @State private var scrollTargetID: String?
    @Namespace private var songNamespace

    private let wheelItemHeight: CGFloat = 280
    private let wheelItemSpacing: CGFloat = 10

    var body: some View {
        ZStack {
            PrototypeTheme.background.ignoresSafeArea()
            
            if viewModel.songs.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                content
            }
        }
        .environment(\.encounterNamespace, songNamespace)
        .task {
            viewModel.loadIfNeeded()
        }
        .fullScreenCover(item: $celebrationSong) { song in
            NavigationStack {
                GeneratedSongNotificationView(
                    song: song,
                    onListenNow: {
                        selectedSong = song
                        celebrationSong = nil
                    },
                    onLater: {
                        celebrationSong = nil
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("閉じる") {
                            celebrationSong = nil
                        }
                        .foregroundStyle(Color.white)
                    }
                }
            }
        }
        .navigationDestination(item: $selectedSong) { song in
            GeneratedSongDetailView(song: song)
        }
    }

    private var content: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Background & Stats
                ZStack {
                    DotGridBackground()
                        .opacity(0.15)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        GeneratedSongsStatsHeader(count: viewModel.songs.count)
                            .padding(.top, geometry.safeAreaInsets.top + 20)
                        Spacer()
                    }
                }
                .opacity(selectedSong == nil ? 1 : 0)

                // Layer 2: Wheel List
                VStack(spacing: 0) {
                    GeometryReader { wheelGeometry in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: wheelItemSpacing) {
                                ForEach(viewModel.songs) { song in
                                    let isCentered = (scrollTargetID ?? viewModel.songs.first?.id) == song.id
                                    
                                    GeometryReader { itemGeometry in
                                        let metrics = wheelMetrics(itemGeometry: itemGeometry, wheelGeometry: wheelGeometry)
                                        
                                        Button {
                                            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                                                selectedSong = song
                                            }
                                        } label: {
                                            GeneratedSongRow(
                                                song: song,
                                                hideMatchedElements: selectedSong?.id == song.id
                                            )
                                            .scaleEffect(metrics.scale)
                                            .opacity(metrics.opacity)
                                            .blur(radius: metrics.blur)
                                            .saturation(metrics.saturation)
                                            .offset(y: metrics.verticalOffset)
                                        }
                                        .buttonStyle(EncounterScaleButtonStyle())
                                        .disabled(!isCentered)
                                    }
                                    .frame(height: wheelItemHeight)
                                    .id(song.id)
                                }
                                
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .padding(.horizontal, 24)
                            .safeAreaPadding(.vertical, max((wheelGeometry.size.height - wheelItemHeight) / 2, 0))
                        }
                        .scrollTargetLayout()
                        .coordinateSpace(name: "songWheel")
                        .scrollPosition(id: $scrollTargetID, anchor: .center)
                        .scrollTargetBehavior(.viewAligned)
                        .scrollClipDisabled()
                    }
                }
                .padding(.top, geometry.safeAreaInsets.top + 8)
            }
        }
    }

    private func wheelMetrics(itemGeometry: GeometryProxy, wheelGeometry: GeometryProxy) -> WheelMetrics {
        let frame = itemGeometry.frame(in: .named("songWheel"))
        let viewportCenter = wheelGeometry.size.height / 2
        let itemCenter = frame.midY
        let distance = abs(itemCenter - viewportCenter)
        let normalizedDistance = min(distance / (wheelItemHeight * 0.8), 1)
        let eased = 1 - pow(1 - normalizedDistance, 2.4)
        
        return WheelMetrics(
            scale: 1.03 - (eased * 0.25),
            opacity: 1.0 - (eased * 0.6),
            blur: eased * 2.0,
            saturation: 1.0 - (eased * 0.3),
            verticalOffset: eased * 20
        )
    }

    private struct WheelMetrics {
        let scale: CGFloat
        let opacity: CGFloat
        let blur: CGFloat
        let saturation: CGFloat
        let verticalOffset: CGFloat
    }

    private var emptyState: some View {
        ZStack {
            // Layer 0: Background Aura
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.08))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: sin(t * 0.4) * 40, y: cos(t * 0.3) * 20)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.05))
                        .frame(width: 250, height: 250)
                        .blur(radius: 60)
                        .offset(x: cos(t * 0.5) * 50, y: sin(t * 0.4) * 30)
                }
            }

            VStack(spacing: 56) {
                // Symbol
                ZStack {
                    Circle()
                        .stroke(Color.indigo.opacity(0.1), lineWidth: 1)
                        .frame(width: 140, height: 140)
                        .scaleEffect(1.2)
                    
                    Image(systemName: viewModel.errorMessage != nil ? "exclamationmark.triangle" : "music.quarternote.3")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundStyle(Color.indigo.gradient)
                        .symbolEffect(.pulse, options: .repeating)
                }

                // Text Content
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text(viewModel.errorMessage != nil ? "CONNECTION ERROR" : "SILENT ARCHIVE")
                            .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                            .kerning(4)
                            .foregroundStyle(Color.indigo.opacity(0.5))

                        Text(viewModel.errorMessage != nil ? "通信が途絶えています" : "まだ静かなライブラリ")
                            .font(PrototypeTheme.Typography.font(size: 22, weight: .black, role: .primary))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                    }

                    Text(viewModel.errorMessage ?? "すれ違いから生まれる、あなただけの音楽を待ちましょう。\n街のどこかで、誰かの言葉が共鳴を待っています。")
                        .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 48)
                        .opacity(0.8)
                }

                // Actions
                VStack(spacing: 16) {
                    if viewModel.errorMessage != nil {
                        SecondaryButton(title: "再読み込み", systemImage: "arrow.clockwise") {
                            viewModel.refresh()
                        }
                    } else {
                        // 能動的な導線
                        NavigationLink {
                            NotificationListView()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bell")
                                    .font(.system(size: 12, weight: .bold))
                                Text("通知履歴を確認する")
                                    .font(PrototypeTheme.Typography.font(size: 13, weight: .black))
                            }
                            .foregroundStyle(Color.indigo)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Color.indigo.opacity(0.06)))
                        }
                        .buttonStyle(EncounterScaleButtonStyle())

                        if let submission = bleCoordinator.latestLyricSubmission {
                            NavigationLink {
                                ChainProgressView(chainId: submission.chain.id)
                            } label: {
                                Text("生成中の進捗を見る")
                                    .font(PrototypeTheme.Typography.font(size: 12, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textTertiary)
                                    .underline()
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .offset(y: -20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GeneratedSongsStatsHeader: View {
    let count: Int

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("COLLECTED ARCHIVES")
                    .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                    .foregroundStyle(PrototypeTheme.textTertiary)
                    .kerning(1.8)
                
                Text("\(count)")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }
            .padding(.leading, 4)
            .opacity(isAnimating ? 1.0 : 0)
            .offset(x: isAnimating ? 0 : -10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}


