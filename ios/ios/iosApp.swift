//
//  iosApp.swift
//  ios
//
//  Created by 三村雄斗 on 2026/03/14.
//

import SwiftUI

@main
struct iosApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var bleEncounterService = BleEncounterService(tokenProvider: EmptyBleTokenProvider())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .prototypeTypography()
                .environmentObject(bleEncounterService)
        }
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            switch newPhase {
            case .active, .background:
                bleEncounterService.start()
            case .inactive:
                bleEncounterService.stop()
            @unknown default:
                bleEncounterService.stop()
            }
        }
    }
}
