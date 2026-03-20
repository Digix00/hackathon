import SwiftUI

struct OnboardingFlowView: View {
    private enum Step: Int, CaseIterable {
        case welcome
        case profile
        case musicServices
        case permissions
        case finish

        var title: String {
            switch self {
            case .welcome: return "はじめよう"
            case .profile: return "プロフィール"
            case .musicServices: return "音楽連携"
            case .permissions: return "権限設定"
            case .finish: return "準備完了"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome: return "A NEW WAY TO CONNECT"
            case .profile: return "HOW OTHERS WILL SEE YOU"
            case .musicServices: return "PLUG IN YOUR SOUND WORLD"
            case .permissions: return "SETTING UP THE BEACON"
            case .finish: return "EVERYTHING IS SET"
            }
        }

        var contentIndex: Int {
            rawValue
        }

        var isLast: Bool {
            self == .finish
        }
    }

    @State private var step: Step = .welcome
    @StateObject private var userViewModel = OnboardingUserViewModel()
    @StateObject private var musicServicesViewModel = MusicServicesViewModel()
    @Environment(\.openURL) private var openURL
    let onFinish: () -> Void

    var body: some View {
        AppScaffold(
            title: stepTitle,
            subtitle: stepSubtitle
        ) {
            VStack(spacing: 32) {
                progress

                Group {
                    switch step {
                    case .welcome:
                        onboardingWelcome
                    case .profile:
                        onboardingProfile
                    case .musicServices:
                        onboardingMusicServices
                    case .permissions:
                        onboardingPermissions
                    default:
                        onboardingFinish
                    }
                }

                if let errorMessage = userViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.error)
                }

                Spacer()

                HStack(spacing: 16) {
                    if showsBackButton {
                        Button(action: {
                            moveToPreviousStep()
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                                .frame(width: 56, height: 56)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(Circle())
                        }
                    }

                    PrimaryButton(
                        title: primaryButtonTitle,
                        isDisabled: isPrimaryButtonDisabled
                    ) {
                        if isLastStep {
                            userViewModel.submitUser(onSuccess: onFinish)
                        } else {
                            moveToNextStep()
                        }
                    }
                }
            }
        }
        .onAppear {
            userViewModel.prefillIfPossible()
        }
        .onOpenURL { url in
            musicServicesViewModel.handleCallbackURL(url)
        }
    }

    private var stepTitle: String {
        step.title
    }

    private var stepSubtitle: String {
        step.subtitle
    }

    private var showsBackButton: Bool {
        step.rawValue > 0 && !isLastStep
    }

    private var isLastStep: Bool {
        step.isLast
    }

    private var primaryButtonTitle: String {
        if isLastStep {
            return userViewModel.isSubmitting ? "処理中..." : "はじめる"
        }
        return "次へ"
    }

    private var isPrimaryButtonDisabled: Bool {
        if isLastStep {
            return userViewModel.isSubmitting
        }
        if step == .profile {
            return !userViewModel.canAdvanceProfile
        }
        return false
    }

    private var progress: some View {
        HStack(spacing: 10) {
            ForEach(Step.allCases, id: \.rawValue) { currentStep in
                Capsule()
                    .fill(currentStep == step ? PrototypeTheme.textPrimary : PrototypeTheme.border)
                    .frame(width: currentStep == step ? 32 : 12, height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moveToPreviousStep() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        withAnimation(.spring()) {
            step = previous
        }
    }

    private func moveToNextStep() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        withAnimation(.spring()) {
            step = next
        }
    }

    private var onboardingWelcome: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(PrototypeTheme.border, lineWidth: 1)
                    .frame(width: 200, height: 200)

                Circle()
                    .stroke(PrototypeTheme.border.opacity(0.5), lineWidth: 1)
                    .frame(width: 260, height: 260)

                Image(systemName: "waveform")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(PrototypeTheme.accent)
            }
            .padding(.vertical, 20)

            VStack(alignment: .leading, spacing: 16) {
                Text("URBAN SERENDIPITY")
                    .font(PrototypeTheme.Typography.Onboarding.eyebrow)
                    .foregroundStyle(PrototypeTheme.accent)
                    .kerning(2.0)

                Text("すれ違う、\n音楽で繋がる。")
                    .font(PrototypeTheme.Typography.Onboarding.title)
                    .foregroundStyle(PrototypeTheme.textPrimary)
                    .lineSpacing(4)

                Text("街を歩くだけで、誰かの「今の気分」と出会える。新しい音楽体験を始めましょう。")
                    .font(PrototypeTheme.Typography.Onboarding.body)
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .lineSpacing(6)
            }
            .padding(.horizontal, 8)
        }
    }

    private var onboardingProfile: some View {
        VStack(spacing: 24) {
            SectionCard(title: "プロフィール") {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(PrototypeTheme.surfaceElevated)
                                .frame(width: 80, height: 80)
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("ニックネーム")
                                .font(PrototypeTheme.Typography.Onboarding.cardLabel)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            TextField("表示名", text: $userViewModel.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ひとこと")
                                .font(PrototypeTheme.Typography.Onboarding.cardLabel)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                            TextEditor(text: $userViewModel.bio)
                                .frame(minHeight: 72)
                                .padding(12)
                                .background(PrototypeTheme.surfaceElevated.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .scrollContentBackground(.hidden)
                        }
                    }
                }
            }

            SectionCard(title: "詳細プロフィール") {
                VStack(alignment: .leading, spacing: 18) {
                    OnboardingMenuPicker(
                        title: "性別",
                        selection: $userViewModel.sex,
                        options: ProfileSex.allCases,
                        selectionValue: \.self
                    ) { sex in
                        Text(sex.label)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $userViewModel.includeBirthdate) {
                            Text("生年月日を設定する")
                                .font(PrototypeTheme.Typography.Onboarding.cardLabel)
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }
                        .tint(PrototypeTheme.accent)

                        if userViewModel.includeBirthdate {
                            DatePicker(
                                "生年月日",
                                selection: $userViewModel.birthdate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)

                            OnboardingMenuPicker(
                                title: "年齢の公開設定",
                                selection: $userViewModel.ageVisibility,
                                options: ProfileAgeVisibility.allCases,
                                selectionValue: \.self
                            ) { visibility in
                                Text(visibility.label)
                            }
                        }
                    }

                    OnboardingMenuPicker(
                        title: "居住地",
                        selection: $userViewModel.prefectureId,
                        options: userViewModel.prefectures,
                        selectionValue: \.id
                    ) { prefecture in
                        Text(prefecture.name)
                    }
                }
            }

            Text("この情報はすれ違った相手にのみ公開されます。")
                .font(.system(size: 13))
                .foregroundStyle(PrototypeTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private var onboardingPermissions: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                PermissionRow(
                    icon: "location.fill",
                    title: "Location Services",
                    description: "近くの人を見つけるために使用します。"
                )
                PermissionRow(
                    icon: "dot.radiowaves.left.and.right",
                    title: "Bluetooth",
                    description: "BLE信号で安全にすれ違いを検知します。"
                )
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "新しい出会いや曲の生成をお知らせします。"
                )
            }

            GlassmorphicCard {
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(PrototypeTheme.success)
                    Text("プライバシーは保護されており、正確な現在地が共有されることはありません。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                }
            }
        }
    }

    private var onboardingMusicServices: some View {
        VStack(spacing: 22) {
            GlassmorphicCard {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SOUND PASSPORT")
                                .font(PrototypeTheme.Typography.Onboarding.eyebrow)
                                .foregroundStyle(PrototypeTheme.accent)
                                .kerning(2.0)

                            Text("聴いている音が、そのまま出会いの輪郭になる。")
                                .font(PrototypeTheme.Typography.Onboarding.stepTitle)
                                .foregroundStyle(PrototypeTheme.textPrimary)
                                .lineSpacing(4)
                        }

                        Spacer(minLength: 16)

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.12, green: 0.72, blue: 0.41).opacity(0.18),
                                            Color(red: 0.96, green: 0.29, blue: 0.39).opacity(0.22)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 72, height: 72)

                            Image(systemName: "waveform.and.person.filled")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                        }
                    }

                    Text("Spotify や Apple Music をつなぐと、あなたの最近のムードや好きな曲をもとに、より自然なすれ違い体験になります。")
                        .font(PrototypeTheme.Typography.Onboarding.body)
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .lineSpacing(5)
                }
            }

            VStack(spacing: 14) {
                OnboardingMusicServiceCard(
                    provider: .spotify,
                    isConnected: musicServicesViewModel.isConnected(.spotify),
                    username: musicServicesViewModel.connection(for: .spotify)?.providerUsername,
                    isWorking: musicServicesViewModel.isActionInProgress(.spotify),
                    accentColor: Color(red: 0.12, green: 0.72, blue: 0.41)
                ) {
                    handleMusicServiceTap(.spotify)
                }

                OnboardingMusicServiceCard(
                    provider: .appleMusic,
                    isConnected: musicServicesViewModel.isConnected(.appleMusic),
                    username: musicServicesViewModel.connection(for: .appleMusic)?.providerUsername,
                    isWorking: musicServicesViewModel.isActionInProgress(.appleMusic),
                    accentColor: Color(red: 0.96, green: 0.29, blue: 0.39)
                ) {
                    handleMusicServiceTap(.appleMusic)
                }
            }

            if musicServicesViewModel.isLoading || musicServicesViewModel.isSaving || musicServicesViewModel.errorMessage != nil {
                SettingsStatusView(
                    isLoading: musicServicesViewModel.isLoading,
                    isSaving: musicServicesViewModel.isSaving,
                    errorMessage: musicServicesViewModel.errorMessage
                )
            }

            if let actionMessage = musicServicesViewModel.actionMessage {
                Text(actionMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PrototypeTheme.success)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(PrototypeTheme.accent)

                Text("連携はあとから設定でも大丈夫です。まずは 1 つつなぐと体験がぐっと自然になります。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textTertiary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            musicServicesViewModel.loadIfNeeded()
        }
    }

    private var onboardingFinish: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(PrototypeTheme.success.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(PrototypeTheme.success)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                Text("READY TO EXPLORE")
                    .font(PrototypeTheme.Typography.Onboarding.eyebrow)
                    .foregroundStyle(PrototypeTheme.success)
                    .kerning(1.5)

                Text("準備が完了しました")
                    .font(PrototypeTheme.Typography.Onboarding.stepTitle)

                Text("iPhoneを持って街に出かけましょう。\n誰かの音楽があなたを待っています。")
                    .font(PrototypeTheme.Typography.Onboarding.body)
                    .foregroundStyle(PrototypeTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
        }
    }

    private func handleMusicServiceTap(_ provider: MusicConnectionProvider) {
        guard !musicServicesViewModel.isActionInProgress(provider), !musicServicesViewModel.isLoading else { return }

        Task {
            if let url = await musicServicesViewModel.startConnection(for: provider) {
                openURL(url)
            }
        }
    }
}

private struct OnboardingMenuPicker<Option: Identifiable, SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    let options: [Option]
    let selectionValue: KeyPath<Option, SelectionValue>
    let content: (Option) -> Content

    init(
        title: String,
        selection: Binding<SelectionValue>,
        options: [Option],
        selectionValue: KeyPath<Option, SelectionValue>,
        @ViewBuilder content: @escaping (Option) -> Content
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.selectionValue = selectionValue
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(PrototypeTheme.Typography.Onboarding.cardLabel)
                .foregroundStyle(PrototypeTheme.textSecondary)

            Picker(title, selection: $selection) {
                if let noneValue = menuPickerNoneValue(for: SelectionValue.self) {
                    Text("未選択").tag(noneValue)
                }
                ForEach(options) { option in
                    content(option).tag(option[keyPath: selectionValue])
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(PrototypeTheme.surfaceElevated.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private func menuPickerNoneValue<T>(for type: T.Type) -> T? {
    if type == String.self {
        return "" as? T
    }
    return nil
}

private struct OnboardingMusicServiceCard: View {
    let provider: MusicConnectionProvider
    let isConnected: Bool
    let username: String?
    let isWorking: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 60, height: 60)

                    Image(systemName: provider == .spotify ? "music.note.list" : "music.note.house")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(provider == .spotify ? "Spotify" : "Apple Music")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(PrototypeTheme.textPrimary)

                        Text(statusTitle)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(statusDescription)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textSecondary)
                        .lineSpacing(3)
                }

                Spacer()

                Image(systemName: isConnected ? "checkmark.circle.fill" : "arrow.up.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isConnected ? PrototypeTheme.success : PrototypeTheme.textTertiary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(PrototypeTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(accentColor.opacity(isConnected ? 0.22 : 0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
    }

    private var statusTitle: String {
        if isWorking {
            return "CONNECTING"
        }
        return isConnected ? "CONNECTED" : "OPTIONAL"
    }

    private var statusDescription: String {
        if let username, !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(username) と接続済み"
        }
        if isConnected {
            return "接続済み。最近の音楽のムードを出会いに反映します。"
        }
        return "最近の再生や好みをもとに、より相性の良い出会いをつくります。"
    }

    private var statusColor: Color {
        if isWorking {
            return PrototypeTheme.accent
        }
        return isConnected ? PrototypeTheme.success : PrototypeTheme.textTertiary
    }
}
