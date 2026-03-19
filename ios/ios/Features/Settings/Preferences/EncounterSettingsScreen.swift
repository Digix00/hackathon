
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
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("BLE STATUS")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Spacer()
                        Text("PRM-BLE")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                    }
                    .padding(.horizontal, 4)

                    GlassmorphicCard {
                        Toggle(isOn: bleToggleBinding) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BLE を有効にする")
                                    .font(.system(size: 17, weight: .bold))
                                Text(bleStatusText)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                        }
                        .tint(PrototypeTheme.success)
                        .disabled(bleCoordinator.isUpdatingBLE)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("DETECTION RADIUS")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Spacer()
                        Text("PRM-DIST")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                    }
                    .padding(.horizontal, 4)

                    GlassmorphicCard {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack {
                                Text("有効半径")
                                    .font(.system(size: 17, weight: .bold))
                                Spacer()
                                Text("\(Int(detectionDistance))m")
                                    .prototypeFont(size: 20, weight: .black, role: .data)
                                    .foregroundStyle(PrototypeTheme.accent)
                            }

                            Slider(value: $detectionDistance, in: 5...100, step: 5)
                                .tint(PrototypeTheme.accent)
                                .disabled(bleCoordinator.isUpdatingEncounterSettings)

                            HStack {
                                Text("MIN: 5m")
                                    .prototypeFont(size: 9, weight: .bold, role: .data)
                                Spacer()
                                Text("MAX: 100m")
                                    .prototypeFont(size: 9, weight: .bold, role: .data)
                            }
                            .foregroundStyle(PrototypeTheme.textTertiary)
                        }
                    }
                    .disabled(bleCoordinator.isUpdatingEncounterSettings)
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("BROADCAST STATUS")
                            .prototypeFont(size: 11, weight: .black, role: .data)
                            .kerning(2.0)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                        Spacer()
                        Text("PRM-VIS")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textTertiary.opacity(0.6))
                    }
                    .padding(.horizontal, 4)

                    SectionCard {
                        Toggle(isOn: $profileVisible) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("公開モード")
                                    .font(.system(size: 17, weight: .bold))
                                Text("周囲のデバイスから検知可能になります")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(PrototypeTheme.textSecondary)
                            }
                        }
                        .tint(PrototypeTheme.success)
                        .padding(.vertical, 4)
                        .disabled(bleCoordinator.isUpdatingEncounterSettings)
                    }
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

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(PrototypeTheme.success)
                            .frame(width: 6, height: 6)
                        Text("REAL-TIME CALIBRATION")
                            .prototypeFont(size: 9, weight: .black, role: .data)
                            .foregroundStyle(PrototypeTheme.textSecondary)
                    }

                    Text("現在、あなたのデバイスは半径 \(Int(detectionDistance))m 以内の BLE ビーコンをスキャンし、自身のシグナルを送信しています。精度は環境（遮蔽物、電波干渉）によって変動します。")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(PrototypeTheme.textTertiary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(PrototypeTheme.surfaceMuted.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 20)
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

    private func submitLocation() {
        locationInputErrorMessage = nil
        guard let lat = Double(locationLat), let lng = Double(locationLng), let accuracy = Double(locationAccuracy) else {
            locationInputErrorMessage = "位置情報は数値で入力してください"
            return
        }
        bleCoordinator.postLocation(lat: lat, lng: lng, accuracyM: accuracy)
    }
}
