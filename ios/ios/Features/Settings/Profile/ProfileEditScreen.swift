import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @StateObject private var viewModel = ProfileEditViewModel()
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        AppScaffold(
            title: "プロフィール",
            subtitle: "あなたの個性を表現しましょう",
            showsBackButton: true
        ) {
            VStack(alignment: .leading, spacing: 40) {
                // アバターセクション：中央配置でゆとりを持たせる
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                if let previewImage = viewModel.previewImage {
                                    Image(uiImage: previewImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                } else if let url = URL(string: viewModel.avatarURL), !viewModel.avatarURL.isEmpty {
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color(PrototypeTheme.surfaceMuted)
                                    }
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(PrototypeTheme.surfaceMuted)
                                        .frame(width: 110, height: 110)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 44))
                                        .foregroundStyle(PrototypeTheme.textTertiary)
                                }
                                
                                Circle()
                                    .stroke(PrototypeTheme.surface, lineWidth: 6)
                                    .frame(width: 110, height: 110)
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            }
                        }
                        
                        Text("写真を変更")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(PrototypeTheme.accent)
                    }
                    Spacer()
                }
                .padding(.top, 12)

                // セクション：広めの余白で情報の塊を独立させる
                VStack(alignment: .leading, spacing: 32) {
                    SectionCard(title: "基本情報") {
                        VStack(alignment: .leading, spacing: 24) {
                            ProfileTextField(
                                title: "ニックネーム",
                                placeholder: "表示名を入力",
                                text: $viewModel.displayName
                            )

                            ProfileTextEditor(
                                title: "自己紹介",
                                placeholder: "好きな音楽や今の気分を自由に書いてみましょう",
                                text: $viewModel.bio
                            )
                        }
                        .padding(.vertical, 8)
                    }

                    SectionCard(title: "詳細設定") {
                        VStack(alignment: .leading, spacing: 24) {
                            ProfilePicker(
                                title: "性別",
                                selection: $viewModel.sex,
                                options: ProfileSex.allCases,
                                selectionValue: \.self
                            ) { sex in
                                Text(sex.label)
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text("生年月日")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .padding(.leading, 4)
                                
                                DatePicker(
                                    "",
                                    selection: $viewModel.birthdate,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            ProfilePicker(
                                title: "年齢の公開設定",
                                selection: $viewModel.ageVisibility,
                                options: ProfileAgeVisibility.allCases,
                                selectionValue: \.self
                            ) { visibility in
                                Text(visibility.label)
                            }

                            ProfilePicker(
                                title: "居住地",
                                selection: $viewModel.prefectureId,
                                options: viewModel.prefectures,
                                selectionValue: \.id
                            ) { pref in
                                Text(pref.name)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // メッセージ表示エリア
                VStack(spacing: 8) {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PrototypeTheme.error)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    if let successMessage = viewModel.successMessage {
                        Text(successMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(PrototypeTheme.success)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(height: 20)

                PrimaryButton(
                    title: viewModel.isSaving ? "保存中..." : "変更を保存する",
                    isDisabled: !viewModel.canSave
                ) {
                    viewModel.save()
                }
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
        .onChange(of: selectedItem) { newItem in
            Task { await viewModel.handleSelectedItem(newItem) }
        }
    }
}

// 共通パーツ：ピッカーのデザイン統一
private struct ProfilePicker<Option: Identifiable, SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    let options: [Option]
    let selectionValue: KeyPath<Option, SelectionValue>
    let content: (Option) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(PrototypeTheme.textSecondary)
                .padding(.leading, 4)
            
            Picker(title, selection: $selection) {
                if let noneValue = profilePickerNoneValue(for: SelectionValue.self) {
                    Text("未選択").tag(noneValue)
                }
                ForEach(options) { option in
                    content(option).tag(option[keyPath: selectionValue])
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(PrototypeTheme.surfaceMuted)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

private func profilePickerNoneValue<T>(for type: T.Type) -> T? {
    if type == String.self {
        return "" as? T
    }
    return nil
}

private struct ProfileTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(PrototypeTheme.textSecondary)
                .padding(.leading, 4)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(PrototypeTheme.surfaceMuted)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct ProfileTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(PrototypeTheme.textSecondary)
                .padding(.leading, 4)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                }
                TextEditor(text: $text)
                    .focused($isFocused)
                    .font(.system(size: 14))
                    .frame(minHeight: 120)
                    .padding(14)
                    .background(PrototypeTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .scrollContentBackground(.hidden)
            }
        }
    }
}
