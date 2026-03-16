import SwiftUI

struct EmptyStatesGalleryView: View {
    @State private var scenario: EmptyScenario = .firstEncounter

    var body: some View {
        AppScaffold(
            title: "空状態・エラー状態",
            subtitle: "例外ケースの表示確認"
        ) {
            VStack(alignment: .leading, spacing: 24) {
                Picker("状態", selection: $scenario) {
                    ForEach(EmptyScenario.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                switch scenario {
                case .firstEncounter:
                    EmptyStateCard(
                        icon: "figure.walk",
                        title: "まだすれ違いがありません",
                        message: "人の多い場所を歩くと出会いやすくなります。",
                        tint: PrototypeTheme.accent
                    )
                case .inactive:
                    EmptyStateCard(
                        icon: "music.note.house",
                        title: "最近の出会いが少ないようです",
                        message: "検知範囲を広げると見つけやすくなります。",
                        tint: PrototypeTheme.warning
                    )
                case .searchEmpty:
                    EmptyStateCard(
                        icon: "magnifyingglass",
                        title: "検索結果がありません",
                        message: "キーワードを変えて試してください。",
                        tint: PrototypeTheme.textSecondary
                    )
                case .network:
                    EmptyStateCard(
                        icon: "wifi.exclamationmark",
                        title: "通信エラー",
                        message: "インターネット接続を確認してください。",
                        tint: PrototypeTheme.error
                    )
                case .bluetooth:
                    EmptyStateCard(
                        icon: "dot.radiowaves.left.and.right.slash",
                        title: "Bluetoothがオフです",
                        message: "近くの人を検知するにはBluetoothが必要です。",
                        tint: PrototypeTheme.info
                    )
                }
            }
        }
    }
}

