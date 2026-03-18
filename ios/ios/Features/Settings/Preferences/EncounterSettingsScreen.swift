import SwiftUI

struct EncounterSettingsView: View {
    @EnvironmentObject private var settingsViewModel: UserSettingsViewModel

    var body: some View {
        AppScaffold(
            title: "すれ違い設定",
            subtitle: "検知範囲と公開設定"
        ) {
            VStack(spacing: 24) {
                SectionCard(title: "検知範囲") {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("半径")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Text("\(Int(settingsViewModel.detectionDistance))m")
                                .prototypeFont(size: 16, weight: .black, role: .data)
                                .foregroundStyle(PrototypeTheme.accent)
                        }

                        Slider(
                            value: $settingsViewModel.detectionDistance,
                            in: 10...100,
                            step: 1
                        ) { editing in
                            if !editing {
                                settingsViewModel.commitDetectionDistance()
                            }
                        }
                        .tint(PrototypeTheme.accent)
                    }
                }

                SectionCard {
                    Toggle(isOn: Binding(
                        get: { settingsViewModel.isProfileVisible },
                        set: { settingsViewModel.setProfileVisible($0) }
                    )) {
                        Text("相手から見つけやすくする")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .tint(PrototypeTheme.success)
                }

                if settingsViewModel.isLoading || settingsViewModel.isSaving || settingsViewModel.errorMessage != nil {
                    SettingsStatusView(
                        isLoading: settingsViewModel.isLoading && !settingsViewModel.hasLoaded,
                        isSaving: settingsViewModel.isSaving,
                        errorMessage: settingsViewModel.errorMessage
                    )
                }
            }
            .disabled(settingsViewModel.isSaving)
            .onAppear { settingsViewModel.loadIfNeeded() }
        }
    }
}
