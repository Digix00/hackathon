import Combine
import SwiftUI

@main
struct iosApp: App {
    @Environment(\.scenePhase) private var scenePhase
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
                .onChange(of: scenePhase) { _, newPhase in
                    bleManager.updateAppForegroundState(newPhase == .active)
                }
                .onReceive(bleManager.$latestDetection.compactMap { $0 }) { detection in
                    Task {
                        await backendClient.enqueueEncounter(
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
        bleManager.updateAppForegroundState(scenePhase == .active)
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

                // Refresh a bit early and add small jitter to avoid synchronized spikes.
                let refreshLeadTime: TimeInterval = 60 * 60
                let refreshJitter: TimeInterval = -Double.random(in: 0...(10 * 60))
                let minRetryInterval: TimeInterval = 60
                let sleepInterval = max(
                    minRetryInterval,
                    advertisingToken.expiresAt.timeIntervalSinceNow - refreshLeadTime + refreshJitter
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
