import SwiftUI

struct EncounterSettingsView: View {
    @EnvironmentObject private var bleCoordinator: BLEAppCoordinator
    @EnvironmentObject private var bleManager: BLEManager

    @State private var detectionDistance: Double = 30
    @State private var profileVisible = true

    @State private var locationLat: String = "35.6586"
    @State private var locationLng: String = "139.7454"
    @State private var locationAccuracy: String = "25"
    @State private var locationInputErrorMessage: String?

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
            subtitle: "PROXIMITY PROTOCOL",
            showsBackButton: true
        ) {
            VStack(alignment: .leading, spacing: 56) {
                // --- Section: BLE STATUS ---
                VStack(alignment: .leading, spacing: 24) {
                    settingLabel("BLE STATUS")

                    Toggle(isOn: bleToggleBinding) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BLE ネットワーク")
                                .font(.system(size: 20, weight: .black))
                                .tracking(-0.5)

                            HStack(spacing: 8) {
                                Circle()
                                    .fill(bleCoordinator.bleEnabled ? PrototypeTheme.success : PrototypeTheme.textTertiary)
                                    .frame(width: 8, height: 8)

                                Text(bleStatusText)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                                    .kerning(0.5)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .tint(PrototypeTheme.success)
                    .disabled(bleCoordinator.isUpdatingBLE)
                }

                // --- Section: DETECTION RADIUS ---
                VStack(alignment: .leading, spacing: 32) {
                    settingLabel("DETECTION RADIUS")

                    VStack(alignment: .leading, spacing: 40) {
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("有効半径")
                                    .font(.system(size: 20, weight: .black))
                                    .tracking(-0.5)
                                Text("周囲をスキャンする範囲")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }

                            Spacer()

                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(Int(detectionDistance))")
                                    .font(.system(size: 48, weight: .black, design: .monospaced))
                                    .tracking(-2)
                                Text("m")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                        }

                        VStack(spacing: 16) {
                            Slider(value: $detectionDistance, in: 5...100, step: 5)
                                .tint(PrototypeTheme.accent)
                                .disabled(bleCoordinator.isUpdatingEncounterSettings)

                            HStack {
                                Text("SHORT")
                                Spacer()
                                Text("WIDE")
                            }
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary)
                            .kerning(1.5)
                        }
                    }
                    .padding(32)
                    .background(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(PrototypeTheme.surface.opacity(0.5))
                            .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 10)
                    )
                }
                .disabled(bleCoordinator.isUpdatingEncounterSettings)

                // --- Section: PRIVACY ---
                VStack(alignment: .leading, spacing: 24) {
                    settingLabel("PRIVACY")

                    Toggle(isOn: $profileVisible) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("公開モード")
                                .font(.system(size: 20, weight: .black))
                                .tracking(-0.5)
                            Text("周囲のデバイスから検知可能になります")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PrototypeTheme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 4)
                    .tint(PrototypeTheme.success)
                    .disabled(bleCoordinator.isUpdatingEncounterSettings)
                }

                // --- Action Area ---
                VStack(alignment: .leading, spacing: 24) {
                    Button {
                        bleCoordinator.updateEncounterSettings(
                            detectionDistance: Int(detectionDistance),
                            profileVisible: profileVisible
                        )
                    } label: {
                        Text("SAVE CONFIGURATION")
                            .prototypeFont(size: 12, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 22)
                            .background(PrototypeTheme.accent)
                            .clipShape(Capsule())
                            .shadow(color: PrototypeTheme.accent.opacity(0.2), radius: 25, x: 0, y: 12)
                    }
                    .buttonStyle(.plain)
                    .disabled(bleCoordinator.isUpdatingEncounterSettings)
                    .opacity(bleCoordinator.isUpdatingEncounterSettings ? 0.6 : 1)

                    if let message = bleCoordinator.settingsErrorMessage {
                        Text(message)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(PrototypeTheme.error)
                    }
                }
                .padding(.top, 12)

                // --- Section: LOCATION POST ---
                SectionCard(title: "位置情報送信") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            TextField("緯度", text: $locationLat)
                                .keyboardType(.numbersAndPunctuation)
                                .padding(12)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            TextField("経度", text: $locationLng)
                                .keyboardType(.numbersAndPunctuation)
                                .padding(12)
                                .background(PrototypeTheme.surfaceMuted)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        TextField("精度 (m)", text: $locationAccuracy)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(PrototypeTheme.surfaceMuted)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        PrimaryButton(title: bleCoordinator.isPostingLocation ? "送信中..." : "位置情報を送信") {
                            submitLocation()
                        }
                        .disabled(bleCoordinator.isPostingLocation)

                        if let message = bleCoordinator.locationPostMessage {
                            Text(message)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.success)
                        }

                        if let errorMessage = locationInputErrorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        } else if let errorMessage = bleCoordinator.locationPostErrorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(PrototypeTheme.error)
                        }
                    }
                }

                // --- Footer Info ---
                Text("現在、あなたのデバイスは半径 \(Int(detectionDistance))m 以内の BLE ビーコンをスキャンし、自身のシグナルを送信しています。精度は環境（遮蔽物、電波干渉）によって変動します。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PrototypeTheme.textTertiary)
                    .lineSpacing(6)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 60)
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

    private func settingLabel(_ text: String) -> some View {
        Text(text)
            .prototypeFont(size: 11, weight: .black, role: .data)
            .kerning(2.5)
            .foregroundStyle(PrototypeTheme.textSecondary.opacity(0.6))
            .padding(.leading, 4)
    }

    private func submitLocation() {
        locationInputErrorMessage = nil

        guard
            let lat = Double(locationLat),
            let lng = Double(locationLng),
            let accuracy = Double(locationAccuracy)
        else {
            locationInputErrorMessage = "位置情報は数値で入力してください"
            return
        }

        bleCoordinator.postLocation(lat: lat, lng: lng, accuracyM: accuracy)
    }
}
