import Combine
import SwiftUI

@MainActor
final class BLEAppCoordinator: ObservableObject {
    let bleManager: BLEManager
    @Published private(set) var latestDetectedUser: BLEPublicUser?
    @Published private(set) var encounters: [Encounter] = []
    @Published private(set) var bleEnabled = true
    @Published private(set) var detectionDistance = 30
    @Published private(set) var profileVisible = true
    @Published private(set) var isLoadingEncounters = false
    @Published private(set) var isLoadingSettings = false
    @Published private(set) var encounterErrorMessage: String?
    @Published private(set) var settingsErrorMessage: String?

    private let backendClient: BLEBackendClient
    private let apiClient: BackendAPIClient
    private var hasStartedBLE = false
    private var tokenRefreshTask: Task<Void, Never>?
    private var detectionSubscription: AnyCancellable?
    private var currentScenePhase: ScenePhase = .active

    init() {
        self.bleManager = BLEManager()
        self.backendClient = BLEBackendClient()
        self.apiClient = BackendAPIClient()
    }

    init(bleManager: BLEManager, backendClient: BLEBackendClient, apiClient: BackendAPIClient) {
        self.bleManager = bleManager
        self.backendClient = backendClient
        self.apiClient = apiClient
    }

    deinit {
        tokenRefreshTask?.cancel()
        detectionSubscription?.cancel()
    }

    func startIfNeeded(scenePhase: ScenePhase) {
        guard !hasStartedBLE else { return }

        hasStartedBLE = true
        currentScenePhase = scenePhase
        bindDetectionsIfNeeded()
        bleManager.updateAppForegroundState(scenePhase == .active)

        Task { [weak self] in
            await self?.bootstrap()
        }
    }

    func updateScenePhase(_ newPhase: ScenePhase) {
        currentScenePhase = newPhase
        bleManager.updateAppForegroundState(newPhase == .active)
    }

    func refreshEncounters() {
        Task { [weak self] in
            await self?.loadEncounters()
        }
    }

    func setBLEEnabled(_ isEnabled: Bool) {
        let previousValue = bleEnabled
        bleEnabled = isEnabled
        applyBLEState()

        Task { [weak self] in
            guard let self else { return }
            do {
                let settings = try await apiClient.patchMySettings(
                    UpdateUserSettingsRequest(bleEnabled: isEnabled)
                )
                await MainActor.run {
                    self.applySettings(settings)
                }
            } catch {
                await MainActor.run {
                    self.settingsErrorMessage = "BLE設定の更新に失敗しました。"
                    self.bleEnabled = previousValue
                    self.applyBLEState()
                }
            }
        }
    }

    func updateEncounterSettings(detectionDistance: Int, profileVisible: Bool) {
        let previousDistance = self.detectionDistance
        let previousVisibility = self.profileVisible
        self.detectionDistance = detectionDistance
        self.profileVisible = profileVisible

        Task { [weak self] in
            guard let self else { return }
            do {
                let settings = try await apiClient.patchMySettings(
                    UpdateUserSettingsRequest(
                        detectionDistance: detectionDistance,
                        profileVisible: profileVisible
                    )
                )
                await MainActor.run {
                    self.applySettings(settings)
                }
            } catch {
                await MainActor.run {
                    self.settingsErrorMessage = "すれ違い設定の更新に失敗しました。"
                    self.detectionDistance = previousDistance
                    self.profileVisible = previousVisibility
                }
            }
        }
    }

    private func bootstrap() async {
        await loadSettings()
        applyBLEState()
        await loadEncounters()
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

                    await self?.loadEncounters()
                }
            }
    }

    private func loadSettings() async {
        await MainActor.run {
            isLoadingSettings = true
            settingsErrorMessage = nil
        }

        do {
            let settings = try await apiClient.getMySettings()
            await MainActor.run {
                applySettings(settings)
                isLoadingSettings = false
            }
        } catch {
            await MainActor.run {
                isLoadingSettings = false
                settingsErrorMessage = "設定の取得に失敗しました。"
            }
        }
    }

    private func loadEncounters() async {
        await MainActor.run {
            isLoadingEncounters = true
            encounterErrorMessage = nil
        }

        do {
            let response = try await apiClient.listEncounters(limit: 50)
            let mappedEncounters = response.encounters.map(Self.makeEncounter(from:))
            await MainActor.run {
                encounters = mappedEncounters
                isLoadingEncounters = false
            }
        } catch {
            await MainActor.run {
                isLoadingEncounters = false
                encounterErrorMessage = "すれ違い履歴の取得に失敗しました。"
            }
        }
    }

    private func applySettings(_ settings: BackendUserSettings) {
        bleEnabled = settings.bleEnabled
        detectionDistance = settings.detectionDistance
        profileVisible = settings.profileVisible
        settingsErrorMessage = nil
    }

    private func applyBLEState() {
        bleManager.updateAppForegroundState(currentScenePhase == .active)

        if bleEnabled {
            bleManager.startScanning()

            if tokenRefreshTask == nil || tokenRefreshTask?.isCancelled == true {
                tokenRefreshTask = Task { [weak self] in
                    await self?.runTokenRefreshLoop()
                }
            }
        } else {
            tokenRefreshTask?.cancel()
            tokenRefreshTask = nil
            bleManager.stopScanning()
            bleManager.stopAdvertising()
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

    private static func makeEncounter(from item: BackendEncounterListItem) -> Encounter {
        let track = makeTrack(from: item.tracks.first)
        return Encounter(
            id: item.id,
            userName: item.user.displayName,
            track: track,
            relativeTime: relativeTimeText(from: item.occurredAt),
            lyric: ""
        )
    }

    private static func makeTrack(from item: BackendEncounterTrack?) -> Track {
        guard let item else {
            return MockData.featuredTrack
        }

        return Track(
            title: item.title,
            artist: item.artistName,
            color: colorSeed(for: item.title + item.artistName),
            artwork: nil
        )
    }

    private static func relativeTimeText(from date: Date?) -> String {
        guard let date else { return "たった今" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let text = formatter.localizedString(for: date, relativeTo: Date())
        return text.replacingOccurrences(of: " ", with: "")
    }

    private static func stableHash(_ s: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }

    private static func colorSeed(for key: String) -> Color {
        let palette: [Color] = [.orange, .teal, .pink, .red, .green, .indigo, .mint]
        let index = Int(stableHash(key) % UInt64(palette.count))
        return palette[index]
    }
}
