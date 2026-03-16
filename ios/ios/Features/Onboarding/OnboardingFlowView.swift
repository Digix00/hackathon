import SwiftUI

struct OnboardingFlowView: View {
    private enum Step: Int, CaseIterable {
        case welcome
        case profile
        case permissions
        case finish

        var title: String {
            switch self {
            case .welcome: return "はじめよう"
            case .profile: return "プロフィール"
            case .permissions: return "権限設定"
            case .finish: return "準備完了"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome: return "A NEW WAY TO CONNECT"
            case .profile: return "HOW OTHERS WILL SEE YOU"
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
                    case .permissions:
                        onboardingPermissions
                    default:
                        onboardingFinish
                    }
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

                    PrimaryButton(title: primaryButtonTitle) {
                        if isLastStep {
                            onFinish()
                        } else {
                            moveToNextStep()
                        }
                    }
                }
            }
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
        isLastStep ? "はじめる" : "次へ"
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
                            Text("miyu")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(PrototypeTheme.textPrimary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("シェアする曲")
                            .font(PrototypeTheme.Typography.Onboarding.cardLabel)
                            .foregroundStyle(PrototypeTheme.textSecondary)

                        HStack(spacing: 14) {
                            MockArtworkView(color: .indigo, symbol: "music.note", size: 52)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("夜に駆ける")
                                    .font(.system(size: 16, weight: .bold))
                                Text("YOASOBI")
                                    .font(.system(size: 14))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                                .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                        .padding(12)
                        .background(PrototypeTheme.surfaceElevated.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
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
}
