import SwiftUI

struct LyricComposerSheet: View {
    private enum Layout {
        static let maxCharacters = 100
    }

    private struct SubmissionSuccessState: Equatable {
        let chainId: String
        let remainingParticipants: Int
    }

    let encounter: Encounter
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var successState: SubmissionSuccessState?

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var remainingCount: Int {
        Layout.maxCharacters - draft.count
    }

    private var canSubmit: Bool {
        !trimmedDraft.isEmpty && remainingCount >= 0 && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if let successState {
                    successContent(successState: successState)
                } else {
                    composerContent
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(successState == nil ? "歌詞投稿" : "投稿完了")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(successState == nil ? "閉じる" : "完了") {
                        bleCoordinator.clearLatestLyricSubmission()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var composerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("✨ この出会いに一言")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(PrototypeTheme.textPrimary)

            Text("\(encounter.userName)とのすれ違いから感じたことを、曲の一節として残せます。")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)

            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $draft)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .padding(12)
                    .frame(minHeight: 140)
                    .background(PrototypeTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("\(draft.count)/\(Layout.maxCharacters)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(remainingCount < 0 ? PrototypeTheme.error : PrototypeTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }

            Text("投稿した歌詞はほかのすれ違いの言葉とつながり、AI が曲に仕上げます。")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)

            HStack {
                Text("残り\(remainingCount)文字")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(remainingCount < 0 ? PrototypeTheme.error : PrototypeTheme.textSecondary)

                Spacer()

                if isSubmitting {
                    ProgressView()
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.error)
            }

            Spacer()

            PrimaryButton(title: "歌詞を残す", systemImage: "sparkles", isDisabled: !canSubmit) {
                submitLyric()
            }

            Button("スキップ") {
                bleCoordinator.clearLatestLyricSubmission()
                dismiss()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(PrototypeTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    private func successContent(successState: SubmissionSuccessState) -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            ZStack {
                Circle()
                    .fill(PrototypeTheme.accent.opacity(0.14))
                    .frame(width: 96, height: 96)

                Image(systemName: "sparkles")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(PrototypeTheme.accent)
            }

            VStack(spacing: 8) {
                Text("歌詞を残しました")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                Text(successState.remainingParticipants > 0
                    ? "あと\(successState.remainingParticipants)人で曲が生まれます。"
                    : "歌詞がそろいました。曲の生成を始めます。")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let latestSubmission = bleCoordinator.latestLyricSubmission {
                Text("“\(latestSubmission.content)”")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }

            Spacer()

            NavigationLink {
                ChainProgressView(chainId: successState.chainId)
            } label: {
                SecondaryButtonLabel(title: "チェーンを見る", systemImage: "sparkles.rectangle.stack")
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                bleCoordinator.clearLatestLyricSubmission()
            })

            Button("閉じる") {
                bleCoordinator.clearLatestLyricSubmission()
                dismiss()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(PrototypeTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func submitLyric() {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        let content = trimmedDraft
        Task {
            do {
                let response = try await bleCoordinator.submitLyric(encounterId: encounter.id, content: content)
                await MainActor.run {
                    isSubmitting = false
                    successState = SubmissionSuccessState(
                        chainId: response.chain.id,
                        remainingParticipants: max(response.chain.threshold - response.chain.participantCount, 0)
                    )
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "歌詞の投稿に失敗しました"
                }
            }
        }
    }
}
