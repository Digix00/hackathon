import SwiftUI

struct SongCreationStudioView: View {
    private struct Route: Hashable, Identifiable {
        let id: String
    }

    @StateObject private var studioStore = LocalCompositionStudioStore.shared
    @State private var draftTitle = ""
    @State private var draftLyric = ""
    @State private var selectedMood = "dreamy"
    @State private var selectedTemplate: LocalCompositionStudioStore.Template?
    @State private var templateLyric = ""
    @State private var activeRoute: Route?
    @State private var pendingRoute: Route?
    @FocusState private var isDraftLyricFocused: Bool
    @FocusState private var isTemplateLyricFocused: Bool

    private let availableMoods = ["dreamy", "upbeat", "melancholic", "bright", "nostalgic"]

    private var canCreateProject: Bool {
        !draftLyric.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                heroCard
                createCard
                templateCard
                progressCard
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
        .background(PrototypeTheme.background.ignoresSafeArea())
        .navigationTitle("作曲スタジオ")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedTemplate) { template in
            templateSheet(template: template)
        }
        .onChange(of: selectedTemplate?.id) { _, currentID in
            guard currentID == nil, let pendingRoute else { return }
            activeRoute = pendingRoute
            self.pendingRoute = nil
        }
        .navigationDestination(item: $activeRoute) { route in
            ChainProgressView(chainId: route.id)
        }
    }

    private var heroCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("START A CHAIN")
                    .font(PrototypeTheme.Typography.font(size: 10, weight: .black, role: .data))
                    .foregroundStyle(PrototypeTheme.accent)
                    .kerning(2)

                Text("自分から曲を始める")
                    .font(PrototypeTheme.Typography.font(size: 28, weight: .black))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                Text("1行の歌詞からチェーンを立ち上げて、サンプルの共鳴を足しながら曲になる流れを体験できます。")
                    .font(PrototypeTheme.Typography.font(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineSpacing(6)
            }
        }
    }

    private var createCard: some View {
        SectionCard(title: "新しく作り始める") {
            VStack(alignment: .leading, spacing: 16) {
                TextField("曲の仮タイトル", text: $draftTitle)
                    .font(.system(size: 18, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(PrototypeTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text("ムード")
                        .font(PrototypeTheme.Typography.Product.sectionLabel)
                        .foregroundStyle(PrototypeTheme.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(availableMoods, id: \.self) { mood in
                                Button {
                                    selectedMood = mood
                                } label: {
                                    Text(mood.uppercased())
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundStyle(selectedMood == mood ? Color.white : PrototypeTheme.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(selectedMood == mood ? PrototypeTheme.textPrimary : PrototypeTheme.surfaceMuted)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("最初の1行")
                        .font(PrototypeTheme.Typography.Product.sectionLabel)
                        .foregroundStyle(PrototypeTheme.textSecondary)

                    TextEditor(text: $draftLyric)
                        .focused($isDraftLyricFocused)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(PrototypeTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .scrollContentBackground(.hidden)
                }

                Text("作成後はチェーン進捗画面でサンプルの歌詞を追加し、完成まで進められます。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textTertiary)

                PrimaryButton(title: "この歌詞でチェーンを始める", systemImage: "sparkles", isDisabled: !canCreateProject) {
                    let chainID = studioStore.createProject(title: draftTitle, mood: selectedMood, openingLyric: draftLyric)
                    draftTitle = ""
                    draftLyric = ""
                    isDraftLyricFocused = false
                    activeRoute = Route(id: chainID)
                }
            }
            .keyboardAvoiding(active: isDraftLyricFocused, padding: 20)
        }
    }

    private var templateCard: some View {
        SectionCard(title: "サンプルチェーンに参加") {
            VStack(spacing: 16) {
                ForEach(studioStore.templates) { template in
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(template.title)
                                    .font(.system(size: 19, weight: .black))
                                    .foregroundStyle(PrototypeTheme.textPrimary)

                                Text(template.summary)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .lineSpacing(4)
                            }

                            Spacer()

                            Text("\(template.seeds.count)/\(template.threshold)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(template.palette.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(template.palette.color.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(template.seeds.prefix(3)) { seed in
                                Text("・\(seed.content)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                        }

                        SecondaryButton(title: "このチェーンで作詞する", systemImage: "pencil.line") {
                            templateLyric = ""
                            selectedTemplate = template
                        }
                    }
                    .padding(18)
                    .background(template.palette.color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private var progressCard: some View {
        SectionCard(title: "作成中のプロジェクト") {
            if studioStore.projectSummaries.isEmpty {
                Text("まだローカルの作曲プロジェクトはありません。上のフォームかサンプルチェーンから始めてください。")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)
            } else {
                VStack(spacing: 14) {
                    ForEach(studioStore.projectSummaries) { project in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(project.title)
                                    .font(.system(size: 17, weight: .black))
                                    .foregroundStyle(PrototypeTheme.textPrimary)
                                Spacer()
                                Text(project.isCompleted ? "COMPLETED" : "PENDING")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(project.isCompleted ? Color.green : project.palette.color)
                            }

                            Text(project.previewLyric)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .lineLimit(2)

                            HStack(spacing: 12) {
                                SecondaryButton(title: "開く", systemImage: "arrow.right") {
                                    activeRoute = Route(id: project.id)
                                }

                                if !project.isCompleted {
                                    SecondaryButton(title: "サンプルで進める", systemImage: "plus.circle") {
                                        studioStore.appendDemoLyric(to: project.id)
                                    }
                                }
                            }

                            Text("\(project.participantCount)/\(project.threshold) 人参加中")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                        .padding(18)
                        .background(PrototypeTheme.surfaceMuted)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private func templateSheet(template: LocalCompositionStudioStore.Template) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(template.title)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(PrototypeTheme.textPrimary)

                Text(template.summary)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textSecondary)

                TextEditor(text: $templateLyric)
                    .focused($isTemplateLyricFocused)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(PrototypeTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .scrollContentBackground(.hidden)

                Spacer()

                PrimaryButton(
                    title: "このチェーンに歌詞を登録",
                    systemImage: "sparkles",
                    isDisabled: templateLyric.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    guard let chainID = studioStore.createProject(from: template.id, userLyric: templateLyric) else { return }
                    pendingRoute = Route(id: chainID)
                    selectedTemplate = nil
                    templateLyric = ""
                    isTemplateLyricFocused = false
                }
            }
            .padding(24)
            .keyboardAvoiding(active: isTemplateLyricFocused, padding: 20)
            .navigationTitle("作詞する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        selectedTemplate = nil
                    }
                }
            }
        }
    }
}
