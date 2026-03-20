import SwiftUI

struct GeneratedSongMockGalleryView: View {
    @State private var coverSong: GeneratedSong?

    private var playableSong: GeneratedSong? {
        MockData.playableGeneratedSongs.first
    }

    private var nonPlayableSong: GeneratedSong? {
        MockData.generatedSongs.first(where: { $0.audioURL == nil })
    }

    private let chainEntries: [(id: String, title: String, subtitle: String)] = [
        ("mock-chain-pending", "チェーン進捗: pending", "参加待ちの状態を確認"),
        ("mock-chain-generating", "チェーン進捗: generating", "生成中ヒーロー表示を確認"),
        ("mock-chain-failed", "チェーン進捗: failed", "失敗状態の表示を確認"),
        ("mock-chain-completed-1", "チェーン進捗: completed", "完成済みから詳細導線を確認")
    ]

    var body: some View {
        AppScaffold(
            title: "生成曲モック",
            subtitle: "DEVELOPER ENTRY",
            showsBackButton: true
        ) {
            VStack(alignment: .leading, spacing: 28) {
                section(
                    title: "主要導線",
                    items: [
                        galleryLink(
                            title: "生成曲一覧",
                            subtitle: "モックの一覧ホイール画面"
                        ) {
                            GeneratedSongsView()
                        },
                        galleryLink(
                            title: "通知一覧",
                            subtitle: "生成完了通知のモックを確認"
                        ) {
                            NotificationListView()
                        }
                    ]
                )

                section(
                    title: "詳細画面",
                    items: [
                        AnyView(
                            Group {
                                if let playableSong {
                                    galleryLink(
                                        title: "詳細: 再生可能",
                                        subtitle: playableSong.title
                                    ) {
                                        GeneratedSongDetailView(song: playableSong)
                                    }
                                }
                            }
                        ),
                        AnyView(
                            Group {
                                if let nonPlayableSong {
                                    galleryLink(
                                        title: "詳細: 音源なし",
                                        subtitle: nonPlayableSong.title
                                    ) {
                                        GeneratedSongDetailView(song: nonPlayableSong)
                                    }
                                }
                            }
                        )
                    ]
                )

                section(
                    title: "チェーン状態",
                    items: chainEntries.map { entry in
                        AnyView(
                            galleryLink(
                                title: entry.title,
                                subtitle: entry.subtitle
                            ) {
                                ChainProgressView(chainId: entry.id)
                            }
                        )
                    }
                )

                section(
                    title: "完了演出",
                    items: [
                        AnyView(
                            Group {
                                if let playableSong {
                                    Button {
                                        coverSong = playableSong
                                    } label: {
                                        galleryRow(
                                            title: "完了演出オーバーレイ",
                                            subtitle: "再生可能モックで full screen を表示"
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        ),
                        galleryLink(
                            title: "通知導線ローダー",
                            subtitle: "GeneratedSongNotificationLoaderView を確認"
                        ) {
                            GeneratedSongNotificationLoaderHostView()
                        }
                    ]
                )
            }
        }
        .fullScreenCover(item: $coverSong) { song in
            NavigationStack {
                GeneratedSongNotificationView(
                    song: song,
                    onListenNow: {
                        coverSong = nil
                    },
                    onLater: {
                        coverSong = nil
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("閉じる") {
                            coverSong = nil
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private func section(title: String, items: [AnyView]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .prototypeFont(size: 11, weight: .black, role: .data)
                .foregroundStyle(PrototypeTheme.textSecondary)
                .kerning(1.8)
                .padding(.horizontal, 8)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    item

                    if index < items.count - 1 {
                        Divider()
                            .background(PrototypeTheme.border.opacity(0.3))
                            .padding(.leading, 24)
                            .padding(.trailing, 24)
                    }
                }
            }
            .background(PrototypeTheme.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(PrototypeTheme.border.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func galleryLink<Destination: View>(
        title: String,
        subtitle: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> AnyView {
        AnyView(
            NavigationLink {
                destination()
            } label: {
                galleryRow(title: title, subtitle: subtitle)
            }
            .buttonStyle(.plain)
        )
    }

    private func galleryRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.5))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 24)
    }
}

private struct GeneratedSongNotificationLoaderHostView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeneratedSongNotificationLoaderView(
            onDismiss: {
                dismiss()
            },
            onListenNow: { _ in
                dismiss()
            }
        )
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
            }
        }
    }
}
