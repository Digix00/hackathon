import SwiftUI

struct LyricComposerSheet: View {
    private enum Layout {
        static let maxCharacters = 100
    }

    private enum Step: Equatable {
        case compose
        case confirm
        case success(SubmissionSuccessState)
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
    @State private var step: Step = .compose
    @State private var hasNavigatedToProgress = false

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
                switch step {
                case .compose:
                    composerContent
                case .confirm:
                    confirmationContent
                case .success(let successState):
                    successContent(successState: successState)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(toolbarTitle) {
                        if shouldClearDraftContext {
                            bleCoordinator.clearLatestLyricSubmission()
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task(id: step) {
            guard case .success = step, !hasNavigatedToProgress else { return }
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled, !hasNavigatedToProgress else { return }
            dismiss()
        }
    }

    private var navigationTitle: String {
        switch step {
        case .compose:
            return "歌詞入力"
        case .confirm:
            return "内容確認"
        case .success:
            return "作成準備完了"
        }
    }

    private var toolbarTitle: String {
        switch step {
        case .success:
            return "完了"
        default:
            return "閉じる"
        }
    }

    private var shouldClearDraftContext: Bool {
        switch step {
        case .success:
            return false
        default:
            return true
        }
    }

    private var composerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("✨ この歌詞が曲の断片になります")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(PrototypeTheme.textPrimary)

            Text("\(encounter.userName)とのすれ違いから生まれた言葉を、Lyria 3 がつなげて1曲に仕上げます。")
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

            Text("投稿した歌詞はほかの断片と混ざり合い、曲の一節として使われます。")
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

            PrimaryButton(title: "この歌詞で曲を作る", systemImage: "sparkles", isDisabled: !canSubmit) {
                errorMessage = nil
                step = .confirm
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

    private var confirmationContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("この内容で曲作成に進みます")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(PrototypeTheme.textPrimary)

            Text("投稿後はほかの参加者の歌詞と合流するため、この断片は編集できません。")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)

            SectionCard(title: "あなたの歌詞") {
                Text("“\(trimmedDraft)”")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            SectionCard(title: "曲になるまで") {
                VStack(alignment: .leading, spacing: 12) {
                    flowRow(number: 1, title: "歌詞を送信", detail: "この出会いの断片としてチェーンに追加されます。")
                    flowRow(number: 2, title: "断片がそろう", detail: "参加人数が満たされると曲生成が始まります。")
                    flowRow(number: 3, title: "Lyria 3 が作曲", detail: "完成したら通知と生成曲一覧から確認できます。")
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.error)
            }

            Spacer()

            PrimaryButton(title: "この歌詞で曲を作る", systemImage: "sparkles", isDisabled: !canSubmit || isSubmitting) {
                submitLyric()
            }

            SecondaryButton(title: "戻る", systemImage: "chevron.left") {
                step = .compose
            }

            if isSubmitting {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("チェーンに追加しています")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
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
                Text("曲作成キューに入りました")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                Text(successState.remainingParticipants > 0
                    ? "あと\(successState.remainingParticipants)人の断片が集まると曲作成が始まります。"
                    : "断片がそろいました。Lyria 3 で曲の生成を始めます。")
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
                    .onAppear {
                        hasNavigatedToProgress = true
                    }
            } label: {
                SecondaryButtonLabel(
                    title: successState.remainingParticipants > 0 ? "進捗を見る" : "生成状況を見る",
                    systemImage: "sparkles.rectangle.stack"
                )
            }
            .buttonStyle(.plain)

            Button("閉じる") {
                dismiss()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(PrototypeTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private func flowRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(PrototypeTheme.textPrimary))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                Text(detail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
                    step = .success(SubmissionSuccessState(
                        chainId: response.chain.id,
                        remainingParticipants: max(response.chain.threshold - response.chain.participantCount, 0)
                    ))
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "歌詞の投稿に失敗しました"
                    step = .confirm
                }
            }
        }
    }
}
