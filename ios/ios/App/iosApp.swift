//
//  iosApp.swift
//  ios
//
//  Created by 三村雄斗 on 2026/03/14.
//

import SwiftUI

@main
struct iosApp: App {
    @StateObject private var bleManager = BLEManager()
    private let bleToken = BLETokenStore.loadOrCreateToken()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .prototypeTypography()
                .environmentObject(bleManager)
                .task {
                    bleManager.startAdvertising(token: bleToken)
                    bleManager.startScanning()
                }
        }
    }
}
