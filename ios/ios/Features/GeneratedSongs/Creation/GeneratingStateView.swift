import SwiftUI

struct GeneratingStateView: View {
    let chain: BackendChainDetail
    let entries: [LyricEntryList.Row]
    let onRefresh: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                SectionCard {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(Color.indigo.opacity(0.12))
                                .frame(width: 104, height: 104)

                            Image(systemName: "waveform.and.sparkles")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(Color.indigo)
                        }

                        VStack(spacing: 8) {
                            Text("Lyria 3 が曲を仕上げています")
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("断片がそろったため、いま楽曲生成が進行中です。閉じても完成したら通知から確認できます。")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                SectionCard(title: "現在の状態") {
                    VStack(alignment: .leading, spacing: 12) {
                        statusRow(label: "ステータス", value: "生成中")
                        statusRow(label: "参加人数", value: "\(chain.participantCount)/\(chain.threshold)")

                        if let createdAt = chain.createdAt {
                            statusRow(label: "開始時刻", value: createdAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }

                SectionCard(title: "集まった歌詞") {
                    LyricEntryList(entries: entries)
                }

                VStack(spacing: 12) {
                    PrimaryButton(title: "通知を待つ", systemImage: "bell.badge") {
                        onClose()
                    }

                    SecondaryButton(title: "進捗を更新", systemImage: "arrow.clockwise") {
                        onRefresh()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 80)
            .padding(.bottom, 100)
        }
    }

    private func statusRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PrototypeTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PrototypeTheme.textPrimary)
        }
    }
}

struct GenerationFailedView: View {
    let chain: BackendChainDetail
    let entries: [LyricEntryList.Row]
    let onRefresh: () -> Void
    let onClose: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                SectionCard {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(PrototypeTheme.error.opacity(0.12))
                                .frame(width: 104, height: 104)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(PrototypeTheme.error)
                        }

                        VStack(spacing: 8) {
                            Text("曲を生成できませんでした")
                                .font(.system(size: 24, weight: .black))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("一時的な問題で Lyria 3 の生成が完了しませんでした。時間を置いて再度確認してください。")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                SectionCard(title: "対象チェーン") {
                    VStack(alignment: .leading, spacing: 12) {
                        statusRow(label: "チェーンID", value: chain.id)
                        statusRow(label: "参加人数", value: "\(chain.participantCount)/\(chain.threshold)")
                    }
                }

                SectionCard(title: "集まった歌詞") {
                    LyricEntryList(entries: entries)
                }

                VStack(spacing: 12) {
                    PrimaryButton(title: "閉じる", systemImage: "music.note.list") {
                        onClose()
                    }

                    SecondaryButton(title: "もう一度確認", systemImage: "arrow.clockwise") {
                        onRefresh()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 80)
            .padding(.bottom, 100)
        }
    }

    private func statusRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PrototypeTheme.textSecondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(PrototypeTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
