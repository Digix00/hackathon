import SwiftUI

struct NotificationListView: View {
    @StateObject private var viewModel = NotificationListViewModel()
    @State private var isShowingGeneratedSongNotification = false
    @State private var notificationTargetSong: GeneratedSong?
    @State private var notificationSourceID: String?
    @State private var scrollTargetID: String?
    @Namespace private var notificationNamespace
    @Environment(\.dismiss) private var dismiss

    private let wheelItemHeight: CGFloat = 180
    private let wheelItemSpacing: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let globalWidth = proxy.frame(in: .global).width
            let layoutWidth = globalWidth > 0 ? min(proxy.size.width, globalWidth) : proxy.size.width

            ZStack {
                // Layer 1: Background & Stats
                DynamicBackground(baseColor: .blue)

                VStack(alignment: .leading, spacing: 0) {
                    NotificationStatsHeader(
                        unreadCount: viewModel.unreadCount,
                        totalCount: viewModel.totalCount
                    )
                    .padding(.top, proxy.safeAreaInsets.top + 8)
                    Spacer()
                }
                .frame(width: layoutWidth)
                .opacity(scrollTargetID != nil ? 1 : 0)

                // Layer 2: Notification Wheel
                if viewModel.notifications.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    notificationWheel(layoutWidth: layoutWidth)
                }
            }
            .frame(width: layoutWidth)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .navigationBarBackButtonHidden()
        .safeAreaInset(edge: .top) {
            headerBar
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .fullScreenCover(isPresented: $isShowingGeneratedSongNotification, onDismiss: {
            guard notificationTargetSong != nil else { return }
        }) {
            NotificationGeneratedSongCover(song: $notificationTargetSong, sourceNotificationID: notificationSourceID) {
                isShowingGeneratedSongNotification = false
                notificationSourceID = nil
            }
        }
        .navigationDestination(item: $notificationTargetSong) { song in
            GeneratedSongDetailView(song: song)
        }
    }

    private var headerBar: some View {
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

    private func notificationWheel(layoutWidth: CGFloat) -> some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = layoutWidth < 390 ? 20 : 24
            let readableWidth = max(layoutWidth - (horizontalPadding * 2), 0)
            let rowWidth = min(readableWidth, 560)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: wheelItemSpacing) {
                    ForEach(viewModel.notifications) { notification in
                        let isCentered = (scrollTargetID ?? viewModel.notifications.first?.id) == notification.id
                        
                        GeometryReader { itemGeometry in
                            let metrics = wheelMetrics(itemGeometry: itemGeometry, wheelGeometry: geometry)
                            
                            NotificationRow(
                                notification: notification,
                                isProcessing: viewModel.isProcessing(id: notification.id),
                                isCentered: isCentered,
                                onOpenGeneratedSong: notification.isGeneratedSongNotification ? {
                                    notificationSourceID = notification.id
                                    isShowingGeneratedSongNotification = true
                                } : nil,
                                onMarkAsRead: {
                                    viewModel.markAsRead(id: notification.id)
                                },
                                onDelete: {
                                    viewModel.deleteNotification(id: notification.id)
                                }
                            )
                            .frame(maxWidth: rowWidth)
                            .frame(maxWidth: .infinity)
                            .scaleEffect(metrics.scale)
                            .opacity(metrics.opacity)
                            .blur(radius: metrics.blur)
                            .saturation(metrics.saturation)
                            .offset(y: metrics.verticalOffset)
                        }
                        .frame(height: wheelItemHeight)
                        .id(notification.id)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .safeAreaPadding(.vertical, max((geometry.size.height - wheelItemHeight) / 2, 0))
                .frame(width: layoutWidth)
            }
            .frame(width: layoutWidth)
            .frame(maxWidth: .infinity, alignment: .center)
            .scrollTargetLayout()
            .coordinateSpace(name: "notificationWheel")
            .scrollPosition(id: $scrollTargetID, anchor: .center)
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
        .padding(.top, 100) // Adjust for stats header
    }

    private func wheelMetrics(itemGeometry: GeometryProxy, wheelGeometry: GeometryProxy) -> WheelMetrics {
        let frame = itemGeometry.frame(in: .named("notificationWheel"))
        let viewportCenter = wheelGeometry.size.height / 2
        let itemCenter = frame.midY
        let distance = abs(itemCenter - viewportCenter)
        let normalizedDistance = min(distance / (wheelItemHeight * 0.8), 1)
        let eased = 1 - pow(1 - normalizedDistance, 2.4)
        
        return WheelMetrics(
            scale: 1.02 - (eased * 0.15),
            opacity: 1.0 - (eased * 0.7),
            blur: eased * 1.5,
            saturation: 1.0 - (eased * 0.4),
            verticalOffset: eased * 12
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
            if let errorMessage = viewModel.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(PrototypeTheme.warning)

                Text("通信エラー")
                    .font(PrototypeTheme.Typography.font(size: 16, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                Text(errorMessage)
                    .font(PrototypeTheme.Typography.font(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "bell.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(PrototypeTheme.textTertiary)

                Text("新しい通知はありません")
                    .font(PrototypeTheme.Typography.font(size: 16, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }

            SecondaryButton(title: "再読み込み", systemImage: "arrow.clockwise") {
                viewModel.refresh()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct NotificationStatsHeader: View {
    let unreadCount: Int
    let totalCount: Int

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("NOTIFICATION LOG")
                    .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                    .foregroundStyle(PrototypeTheme.textTertiary)
                    .kerning(1.8)
                
                Text("\(unreadCount) UNREAD")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(unreadCount > 0 ? Color.blue : PrototypeTheme.textSecondary)
            }
            .padding(.leading, 4)
            
            Text("NOTIFICATIONS")
                .font(.system(size: 42, weight: .black))
                .foregroundStyle(PrototypeTheme.textPrimary)
                .tracking(-2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
        .opacity(isAnimating ? 1.0 : 0)
        .offset(y: isAnimating ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}

private struct NotificationRow: View {
    let notification: NotificationListViewModel.NotificationRowModel
    let isProcessing: Bool
    let isCentered: Bool
    let onOpenGeneratedSong: (() -> Void)?
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background Aura for unread
            if !notification.isRead {
                auraView
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    // Status Icon
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(statusColor)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(titleText)
                                .font(PrototypeTheme.Typography.font(size: 18, weight: .black))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                            
                            Spacer()
                            
                            Text(timeText)
                                .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                                .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
                        }

                        if !notification.encounterId.isEmpty {
                            Text("ID: \(notification.encounterId)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                    }
                }

                if isCentered {
                    HStack(spacing: 12) {
                        if let onOpenGeneratedSong {
                            NotificationActionButton(
                                title: "開く",
                                systemImage: "sparkles",
                                tint: .blue,
                                action: onOpenGeneratedSong
                            )
                        }

                        if !notification.isRead {
                            NotificationActionButton(
                                title: "既読",
                                systemImage: "checkmark",
                                tint: PrototypeTheme.textSecondary,
                                action: onMarkAsRead
                            )
                        }

                        NotificationActionButton(
                            title: "削除",
                            systemImage: "trash",
                            tint: PrototypeTheme.error.opacity(0.8),
                            action: onDelete
                        )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(PrototypeTheme.surface.opacity(notification.isRead ? 0.4 : 0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(notification.isRead ? Color.clear : statusColor.opacity(0.2), lineWidth: 1)
            )
            .opacity(isProcessing ? 0.6 : 1.0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusIcon: String {
        let status = notification.status.lowercased()
        if status.contains("encounter") { return "person.2.fill" }
        if notification.isGeneratedSongNotification { return "music.note.sparkles" }
        if status.contains("comment") { return "bubble.left.fill" }
        if status.contains("like") { return "heart.fill" }
        return "bell.fill"
    }

    private var statusColor: Color {
        if notification.isRead { return PrototypeTheme.textSecondary }
        let status = notification.status.lowercased()
        if status.contains("encounter") { return .teal }
        if notification.isGeneratedSongNotification { return .indigo }
        if status.contains("error") { return PrototypeTheme.error }
        return .blue
    }

    private var titleText: String {
        let status = notification.status.lowercased()
        if status.contains("encounter") { return "新しいすれ違い" }
        if notification.isGeneratedSongNotification { return "曲が完成しました" }
        if status.contains("announcement") { return "お知らせ" }
        if status.contains("comment") { return "新着コメント" }
        if status.contains("like") { return "いいね！" }
        return "通知"
    }

    private var timeText: String {
        relativeTime(from: notification.createdAt)
    }

    private func relativeTime(from date: Date?) -> String {
        guard let date else { return "時刻不明" }
        let calendar = Calendar.current
        if calendar.isDateInYesterday(date) { return "昨日" }
        if !calendar.isDateInToday(date) {
            let dayDelta = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: Date())).day ?? 0
            return dayDelta > 1 ? "\(dayDelta)日前" : "昨日"
        }
        let minutes = Int(max(0, Date().timeIntervalSince(date)) / 60)
        if minutes < 1 { return "たった今" }
        if minutes < 60 { return "\(minutes)分前" }
        return "\(minutes / 60)時間前"
    }

    private var auraView: some View {
        let interval = reduceMotion ? 1.0 / 10.0 : 1.0 / 20.0
        return TimelineView(.animation(minimumInterval: interval)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 1 + CGFloat(sin(t * 1.2) * 0.05)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [statusColor.opacity(0.12), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .scaleEffect(pulse)
                .blur(radius: 40)
        }
    }
}

private struct NotificationActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .black))
            }
            .foregroundStyle(tint)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(PrototypeTheme.surface.opacity(0.6))
            .clipShape(Capsule())
        }
    }
}

private struct NotificationGeneratedSongCover: View {
    @Binding var song: GeneratedSong?
    let sourceNotificationID: String?
    let onDismiss: () -> Void

    var body: some View {
        GeneratedSongNotificationLoaderView(
            sourceNotificationID: sourceNotificationID,
            onDismiss: onDismiss,
            onListenNow: { loadedSong in
                song = loadedSong
                onDismiss()
            }
        )
    }
}
