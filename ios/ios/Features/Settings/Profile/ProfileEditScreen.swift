import SwiftUI

struct ProfileEditView: View {
    @StateObject private var viewModel = ProfileEditViewModel()

    var body: some View {
        AppScaffold(
            title: "プロフィール",
            subtitle: "公開される情報を管理"
        ) {
            VStack(alignment: .leading, spacing: 28) {
                SectionCard(title: "基本情報") {
                    VStack(alignment: .leading, spacing: 20) {
                        ProfileTextField(
                            title: "ニックネーム",
                            placeholder: "表示名を入力",
                            text: $viewModel.displayName
                        )

                        ProfileTextEditor(
                            title: "ひとこと",
                            placeholder: "気分や音楽のことを短く",
                            text: $viewModel.bio
                        )
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                }

                if let successMessage = viewModel.successMessage {
                    Text(successMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.success)
                }

                PrimaryButton(
                    title: viewModel.isSaving ? "保存中..." : "保存",
                    isDisabled: !viewModel.canSave
                ) {
                    viewModel.save()
                }
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }
}

private struct ProfileTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(PrototypeTheme.textSecondary)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(PrototypeTheme.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct ProfileTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(PrototypeTheme.textSecondary)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $text)
                    .focused($isFocused)
                    .frame(minHeight: 96)
                    .padding(12)
                    .background(PrototypeTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .scrollContentBackground(.hidden)
            }
        }
    }
}
