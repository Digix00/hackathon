import SwiftUI

struct EncounterSettingsView: View {
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator
    @EnvironmentObject private var bleManager: BLEManager
    @State private var detectionDistance: Double = 30
    @State private var profileVisible = true

    private var bleToggleBinding: Binding<Bool> {
        Binding(
            get: { bleCoordinator.bleEnabled },
            set: { bleCoordinator.setBLEEnabled($0) }
        )
    }

    private var bleStatusText: String {
        guard bleCoordinator.bleEnabled else { return "オフ" }

        switch bleManager.state {
        case .poweredOn:
            return bleManager.isAdvertising ? "配信中" : "待機中"
        case .poweredOff:
            return "Bluetooth オフ"
        case .unauthorized:
            return "権限なし"
        case .unsupported:
            return "非対応"
        case .unknown:
            return "確認中"
        }
    }

    var body: some View {
        AppScaffold(
            title: "すれ違い設定",
            subtitle: "検知範囲と公開設定"
        ) {
            VStack(spacing: 24) {
                SectionCard(title: "BLE") {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: bleToggleBinding) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BLE を有効にする")
                                    .font(.system(size: 16, weight: .bold))
                                Text(bleStatusText)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                        }
                        .tint(PrototypeTheme.success)
                        .disabled(bleCoordinator.isUpdatingBLE)
                    }
                }

                SectionCard(title: "検知範囲") {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("半径")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Text("\(Int(detectionDistance))m")
                                .prototypeFont(size: 16, weight: .black, role: .data)
                                .foregroundStyle(PrototypeTheme.accent)
                        }
                        
                        Slider(value: $detectionDistance, in: 5...100, step: 5)
                            .tint(PrototypeTheme.accent)
                    }
                    .disabled(bleCoordinator.isUpdatingEncounterSettings)
                }

                SectionCard {
                    Toggle(isOn: $profileVisible) {
                        Text("相手から見つけやすくする")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .tint(PrototypeTheme.success)
                    .disabled(bleCoordinator.isUpdatingEncounterSettings)
                }

                Button {
                    bleCoordinator.updateEncounterSettings(
                        detectionDistance: Int(detectionDistance),
                        profileVisible: profileVisible
                    )
                } label: {
                    Text("設定を保存")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(PrototypeTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(PrototypeTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(bleCoordinator.isUpdatingEncounterSettings)
                .opacity(bleCoordinator.isUpdatingEncounterSettings ? 0.6 : 1)

                if let message = bleCoordinator.settingsErrorMessage {
                    Text(message)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear {
            detectionDistance = Double(bleCoordinator.detectionDistance)
            profileVisible = bleCoordinator.profileVisible
        }
        .onChange(of: bleCoordinator.detectionDistance) { _, newValue in
            detectionDistance = Double(newValue)
        }
        .onChange(of: bleCoordinator.profileVisible) { _, newValue in
            profileVisible = newValue
        }
    }
}
