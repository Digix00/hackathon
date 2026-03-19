import SwiftUI

struct LyricComposerSheet: View {
    private enum Layout {
        static let maxCharacters = 100
    }

    let encounter: Encounter
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

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
            VStack(alignment: .leading, spacing: 16) {
                Text("\(encounter.userName)とのすれ違いに残す歌詞")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                TextEditor(text: $draft)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .padding(12)
                    .frame(minHeight: 140)
                    .background(PrototypeTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

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

                Button(action: submitLyric) {
                    HStack {
                        Spacer()
                        Text("歌詞を送信")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                    }
                    .frame(height: 52)
                    .background(canSubmit ? PrototypeTheme.accent : PrototypeTheme.surfaceElevated)
                    .foregroundStyle(canSubmit ? Color.white : PrototypeTheme.textSecondary)
                    .clipShape(Capsule())
                }
                .disabled(!canSubmit)
            }
            .padding(24)
            .navigationTitle("歌詞投稿")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func submitLyric() {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        let content = trimmedDraft
        Task {
            do {
                _ = try await bleCoordinator.submitLyric(encounterId: encounter.id, content: content)
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
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
