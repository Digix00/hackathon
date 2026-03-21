import SwiftUI

struct EncounterCommentsSection: View {
    let encounter: Encounter
    @StateObject private var viewModel = EncounterCommentsViewModel()
    @State private var draft = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            commentsBody
            composer
        }
        .padding(.horizontal, 24)
        .padding(.top, 96)
        .onAppear {
            viewModel.loadIfNeeded(encounterId: encounter.id)
        }
        .onChange(of: encounter.id) { _, newValue in
            viewModel.loadIfNeeded(encounterId: newValue)
        }
    }

    private var header: some View {
        Text("コメント")
            .font(PrototypeTheme.Typography.font(size: 11, weight: .black, role: .data))
            .foregroundStyle(encounter.track.color.opacity(0.6))
            .kerning(3)
            .padding(.leading, 8)
    }

    @ViewBuilder
    private var commentsBody: some View {
        if viewModel.isLoading && viewModel.comments.isEmpty {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        } else if let message = viewModel.errorMessage, viewModel.comments.isEmpty {
            Text(message)
                .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 8)
        } else if viewModel.comments.isEmpty {
            Text("まだコメントがありません")
                .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                .foregroundStyle(PrototypeTheme.textSecondary)
                .padding(.horizontal, 8)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.comments) { comment in
                    EncounterCommentRow(
                        comment: comment,
                        accentColor: encounter.track.color,
                        avatarColor: avatarColor(for: comment.userID ?? comment.userName)
                    ) {
                        viewModel.deleteComment(comment)
                    }
                }
            }
        }
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                TextField("想いを届ける", text: $draft)
                    .font(PrototypeTheme.Typography.font(size: 15, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .focused($isInputFocused)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(PrototypeTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(encounter.track.color.opacity(0.2), lineWidth: 1)
                    )

                Button {
                    let payload = draft
                    Task {
                        let success = await viewModel.submitComment(
                            encounterId: encounter.id,
                            content: payload
                        )
                        if success {
                            draft = ""
                            isInputFocused = false
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(encounter.track.color)
                            .frame(width: 44, height: 44)
                            .shadow(color: encounter.track.color.opacity(0.3), radius: 12, x: 0, y: 6)

                        if viewModel.isSubmitting {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSubmitting)
                .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }

            if let message = viewModel.submitErrorMessage {
                Text(message)
                    .font(PrototypeTheme.Typography.font(size: 12, weight: .medium))
                    .foregroundStyle(PrototypeTheme.error)
                    .padding(.leading, 8)
            }
        }
        .keyboardAvoiding(active: isInputFocused, padding: 20)
    }

    private func avatarColor(for key: String) -> Color {
        let palette: [Color] = [
            .indigo,
            .orange,
            .teal,
            .pink,
            .red,
            .green,
            .purple,
            .blue,
            .mint
        ]
        let index = Int(UInt(bitPattern: key.hashValue) % UInt(palette.count))
        return palette[index]
    }
}

private struct EncounterCommentRow: View {
    let comment: EncounterComment
    let accentColor: Color
    let avatarColor: Color
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            EncounterAvatarView(userName: comment.userName, color: avatarColor, size: 40)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(comment.userName)
                        .font(PrototypeTheme.Typography.font(size: 14, weight: .bold))
                        .foregroundStyle(PrototypeTheme.textPrimary)

                    Text(comment.relativeTime.uppercased())
                        .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                        .kerning(1.5)
                        .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.5))

                    Spacer()
                }

                Text(comment.content)
                    .font(PrototypeTheme.Typography.font(size: 15, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textPrimary.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(PrototypeTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(accentColor.opacity(0.12), lineWidth: 1)
            )
        }
        .contextMenu {
            if comment.isMine, comment.backendID != nil {
                Button(role: .destructive, action: onDelete) {
                    Text("削除")
                }
            }
        }
    }
}
