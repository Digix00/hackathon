//
//  iosApp.swift
//  ios
//
//  Created by 三村雄斗 on 2026/03/14.
//

import Combine
import SwiftUI

@main
struct iosApp: App {
    @StateObject private var bleManager = BLEManager()
    private let backendClient = BLEBackendClient()
    @State private var hasStartedBLE = false
    @State private var tokenRefreshTask: Task<Void, Never>?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .prototypeTypography()
                .environmentObject(bleManager)
                .task {
                    startBLEIfNeeded()
                }
                .onReceive(bleManager.$latestDetection.compactMap { $0 }) { detection in
                    Task {
                        try? await backendClient.postEncounter(
                            targetBLEToken: detection.token,
                            rssi: detection.rssi,
                            occurredAt: detection.detectedAt
                        )
                    }
                }
        }
    }

    private func startBLEIfNeeded() {
        guard !hasStartedBLE else { return }

        hasStartedBLE = true
        bleManager.startScanning()

        tokenRefreshTask?.cancel()
        tokenRefreshTask = Task {
            await runTokenRefreshLoop()
        }
    }

    private func runTokenRefreshLoop() async {
        while !Task.isCancelled {
            do {
                let advertisingToken = try await backendClient.fetchOrIssueCurrentToken()
                await MainActor.run {
                    bleManager.startAdvertising(token: advertisingToken.token)
                }

                let refreshLeadTime: TimeInterval = 5 * 60
                let minRetryInterval: TimeInterval = 60
                let sleepInterval = max(
                    minRetryInterval,
                    advertisingToken.expiresAt.timeIntervalSinceNow - refreshLeadTime
                )

                try await Task.sleep(nanoseconds: UInt64(sleepInterval * 1_000_000_000))
            } catch {
                await MainActor.run {
                    bleManager.stopAdvertising()
                }
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
            }
        }
    }
}
