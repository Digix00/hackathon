import Combine
import SwiftUI

@MainActor
final class BLEAppCoordinator: ObservableObject {
    let bleManager: BLEManager
    @Published private(set) var latestDetectedUser: BLEPublicUser?

    private let backendClient: BLEBackendClient
    private var hasStartedBLE = false
    private var tokenRefreshTask: Task<Void, Never>?
    private var detectionSubscription: AnyCancellable?

    init() {
        self.bleManager = BLEManager()
        self.backendClient = BLEBackendClient()
    }

    init(bleManager: BLEManager, backendClient: BLEBackendClient) {
        self.bleManager = bleManager
        self.backendClient = backendClient
    }

    deinit {
        tokenRefreshTask?.cancel()
        detectionSubscription?.cancel()
    }

    func startIfNeeded(scenePhase: ScenePhase) {
        guard !hasStartedBLE else { return }

        hasStartedBLE = true
        bindDetectionsIfNeeded()
        bleManager.updateAppForegroundState(scenePhase == .active)
        bleManager.startScanning()

        tokenRefreshTask?.cancel()
        tokenRefreshTask = Task { [weak self] in
            await self?.runTokenRefreshLoop()
        }
    }

    func updateScenePhase(_ newPhase: ScenePhase) {
        bleManager.updateAppForegroundState(newPhase == .active)
    }

    private func bindDetectionsIfNeeded() {
        guard detectionSubscription == nil else { return }

        detectionSubscription = bleManager.$latestDetection
            .compactMap { $0 }
            .sink { [backendClient] detection in
                Task { [weak self] in
                    await backendClient.enqueueEncounter(
                        targetBLEToken: detection.token,
                        rssi: detection.rssi,
                        occurredAt: detection.detectedAt
                    )

                    do {
                        let user = try await backendClient.fetchUser(forBLEToken: detection.token)
                        await MainActor.run {
                            self?.latestDetectedUser = user
                        }
                    } catch {
                        // Ignore lookup failures (expired token / blocked / network).
                    }
                }
            }
    }

    private func runTokenRefreshLoop() async {
        while !Task.isCancelled {
            do {
                let advertisingToken = try await backendClient.fetchOrIssueCurrentToken()
                bleManager.startAdvertising(token: advertisingToken.token)

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
                bleManager.stopAdvertising()
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
            }
        }
    }
}
