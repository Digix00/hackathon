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
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundStyle(PrototypeTheme.textTertiary)
            
            VStack(spacing: 8) {
                Text(viewModel.errorMessage ?? "生成された曲がまだありません")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                
                Text("すれ違いから生まれる、あなただけの音楽を待ちましょう。")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if viewModel.errorMessage != nil {
                SecondaryButton(title: "再読み込み", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
            }
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


