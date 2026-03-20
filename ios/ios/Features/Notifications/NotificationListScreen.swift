import SwiftUI

struct NotificationListView: View {
    @StateObject private var viewModel = NotificationListViewModel()
    @State private var isShowingGeneratedSongNotification = false
    @State private var notificationTargetSong: GeneratedSong?

    var body: some View {
        AppScaffold(
            title: "通知",
            subtitle: viewModel.subtitleText,
            showsBackButton: true
        ) {
            VStack(spacing: 24) {
                if let message = viewModel.errorMessage {
                    EmptyStateCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "通信エラー",
                        message: message,
                        tint: PrototypeTheme.warning
                    )
                }

                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    SectionCard {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("通知を読み込んでいます")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                } else if viewModel.notifications.isEmpty, viewModel.errorMessage == nil {
                    EmptyStateCard(
                        icon: "bell.slash.fill",
                        title: "通知はまだありません",
                        message: "生成完了やすれ違いの通知が届くとここに表示されます。",
                        tint: PrototypeTheme.textSecondary
                    )
                } else {
                    SectionCard(title: "通知一覧") {
                        VStack(spacing: 16) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationRow(
                                    notification: notification,
                                    isProcessing: viewModel.isProcessing(id: notification.id),
                                    onOpenGeneratedSong: notification.isGeneratedSongNotification ? {
                                        isShowingGeneratedSongNotification = true
                                    } : nil,
                                    onMarkAsRead: {
                                        viewModel.markAsRead(id: notification.id)
                                    },
                                    onDelete: {
                                        viewModel.deleteNotification(id: notification.id)
                                    }
                                )
                            }
                        }
                    }
                }

                SecondaryButton(title: "再読み込み", systemImage: "arrow.clockwise") {
                    viewModel.refresh()
                }
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .fullScreenCover(isPresented: $isShowingGeneratedSongNotification) {
            NotificationGeneratedSongCover(song: $notificationTargetSong) {
                isShowingGeneratedSongNotification = false
                notificationTargetSong = nil
            }
        }
        .navigationDestination(item: $notificationTargetSong) { song in
            GeneratedSongDetailView(song: song)
        }
    }
}

private struct NotificationGeneratedSongCover: View {
    @Binding var song: GeneratedSong?
    let onDismiss: () -> Void

    var body: some View {
        GeneratedSongNotificationLoaderView(
            onDismiss: onDismiss,
            onListenNow: { loadedSong in
                song = loadedSong
                onDismiss()
            }
        )
    }
}

private struct NotificationRow: View {
    let notification: NotificationListViewModel.NotificationRowModel
    let isProcessing: Bool
    let onOpenGeneratedSong: (() -> Void)?
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(notification.isRead ? PrototypeTheme.textTertiary : PrototypeTheme.info)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(titleText)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(PrototypeTheme.textPrimary)
                        Spacer()
                        Text(timeText)
                            .font(PrototypeTheme.Typography.font(size: 11, weight: .bold, role: .data))
                            .foregroundStyle(PrototypeTheme.textSecondary)
                            .kerning(1.2)
                    }

                    Text("すれ違いID: \(notification.encounterId)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)

                    if !statusDetail.isEmpty {
                        Text(statusDetail)
                            .font(PrototypeTheme.Typography.font(size: 10, weight: .bold, role: .data))
                            .foregroundStyle(PrototypeTheme.textTertiary)
                            .kerning(1.0)
                    }
                }
            }

            HStack(spacing: 12) {
                if let onOpenGeneratedSong {
                    NotificationActionButton(
                        title: "開く",
                        systemImage: "sparkles",
                        tint: PrototypeTheme.accent,
                        isDisabled: isProcessing,
                        action: onOpenGeneratedSong
                    )
                }

                if !notification.isRead {
                    NotificationActionButton(
                        title: "既読にする",
                        systemImage: "checkmark",
                        tint: PrototypeTheme.info,
                        isDisabled: isProcessing,
                        action: onMarkAsRead
                    )
                }

                NotificationActionButton(
                    title: "削除",
                    systemImage: "trash",
                    tint: PrototypeTheme.error,
                    isDisabled: isProcessing,
                    action: onDelete
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrototypeTheme.surfaceMuted.opacity(notification.isRead ? 0.55 : 0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(isProcessing ? 0.6 : 1.0)
    }

    private var titleText: String {
        let status = notification.status.lowercased()
        if status.contains("encounter") {
            return "すれ違い通知"
        }
        if status.contains("song") || status.contains("track") || status.contains("generated") {
            return "生成完了通知"
        }
        if status.contains("announcement") {
            return "お知らせ"
        }
        if status.contains("comment") {
            return "コメント通知"
        }
        if status.contains("like") {
            return "いいね通知"
        }
        return "通知"
    }

    private var statusDetail: String {
        let trimmed = notification.status.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : "STATUS: \(trimmed)"
    }

    private var timeText: String {
        relativeTime(from: notification.createdAt)
    }

    private func relativeTime(from date: Date?) -> String {
        guard let date else {
            return "時刻不明"
        }

        let calendar = Calendar.current
        if calendar.isDateInYesterday(date) {
            return "昨日"
        }
        if !calendar.isDateInToday(date) {
            let now = Date()
            let startOfDate = calendar.startOfDay(for: date)
            let startOfNow = calendar.startOfDay(for: now)
            let dayDelta = calendar.dateComponents([.day], from: startOfDate, to: startOfNow).day ?? 0
            if dayDelta > 1 {
                return "\(dayDelta)日前"
            }
            if dayDelta < 0 {
                return "近日"
            }
            return "昨日"
        }

        let now = Date()
        let interval = max(0, now.timeIntervalSince(date))
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "たった今"
        }
        if minutes < 60 {
            return "\(minutes)分前"
        }

        let hours = Int(Double(minutes) / 60.0)
        return "\(hours)時間前"
    }
}

private struct NotificationActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(PrototypeTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}
