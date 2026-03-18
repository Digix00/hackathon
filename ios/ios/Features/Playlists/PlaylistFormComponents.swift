import SwiftUI

struct PlaylistEditorSheet: View {
    let title: String
    let confirmLabel: String
    let initialName: String
    let initialDescription: String
    let initialIsPublic: Bool
    let isSaving: Bool
    let onSubmit: (String, String, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var description: String
    @State private var isPublic: Bool

    init(
        title: String,
        confirmLabel: String,
        initialName: String,
        initialDescription: String,
        initialIsPublic: Bool,
        isSaving: Bool,
        onSubmit: @escaping (String, String, Bool) -> Void
    ) {
        self.title = title
        self.confirmLabel = confirmLabel
        self.initialName = initialName
        self.initialDescription = initialDescription
        self.initialIsPublic = initialIsPublic
        self.isSaving = isSaving
        self.onSubmit = onSubmit
        _name = State(initialValue: initialName)
        _description = State(initialValue: initialDescription)
        _isPublic = State(initialValue: initialIsPublic)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                PlaylistTextField(title: "名前", placeholder: "プレイリスト名", text: $name)

                PlaylistTextEditor(title: "説明", placeholder: "どんな気分のプレイリスト？", text: $description)

                Toggle(isOn: $isPublic) {
                    Text("公開する")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PrototypeTheme.textPrimary)
                }
                .tint(PrototypeTheme.accent)

                PrimaryButton(title: isSaving ? "処理中..." : confirmLabel, isDisabled: name.isEmpty || isSaving) {
                    onSubmit(name, description, isPublic)
                    dismiss()
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PlaylistTextField: View {
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

struct PlaylistTextEditor: View {
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
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(PrototypeTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .scrollContentBackground(.hidden)
            }
        }
    }
}
