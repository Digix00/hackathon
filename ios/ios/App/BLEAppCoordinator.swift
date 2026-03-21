import Combine
import SwiftUI

@MainActor
final class BLEAppCoordinator: ObservableObject {
    struct LatestLyricSubmission: Equatable {
        let chain: BackendLyricChainSummary
        let content: String

        var remainingParticipants: Int {
            max(chain.threshold - chain.participantCount, 0)
        }
    }

    let bleManager: BLEManager
    @Published private(set) var latestDetectedUser: BLEPublicUser?
    @Published private(set) var encounters: [Encounter] = []
    @Published private(set) var bleEnabled = true
    @Published private(set) var detectionDistance = 30
    @Published private(set) var profileVisible = true
    @Published private(set) var isUpdatingBLE = false
    @Published private(set) var isUpdatingEncounterSettings = false
    @Published private(set) var isLoadingEncounters = false
    @Published private(set) var isLoadingSettings = false
    @Published private(set) var encounterErrorMessage: String?
    @Published private(set) var settingsErrorMessage: String?
    @Published private(set) var latestLyricChain: BackendLyricChainSummary?
    @Published private(set) var latestLyricSubmission: LatestLyricSubmission?
    @Published private(set) var isPostingLocation = false
    @Published private(set) var locationPostMessage: String?
    @Published private(set) var locationPostErrorMessage: String?
    @Published private(set) var lastLocationEncounterCount: Int?

    private let backendClient: BLEBackendClient
    private let apiClient: BackendAPIClient
    private var hasStartedBLE = false
    private var tokenRefreshTask: Task<Void, Never>?
    private var bleSettingsUpdateTask: Task<Void, Never>?
    private var encounterSettingsUpdateTask: Task<Void, Never>?
    private var bleSettingsRequestVersion = 0
    private var encounterSettingsRequestVersion = 0
    private var detectionSubscription: AnyCancellable?
    private var currentScenePhase: ScenePhase = .active
    private var readRequestInFlight: Set<String> = []
    private var markedReadEncounterIDs: Set<String> = []

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
        bleSettingsUpdateTask?.cancel()
        encounterSettingsUpdateTask?.cancel()
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

    func markEncounterRead(id: String) {
        guard !markedReadEncounterIDs.contains(id), !readRequestInFlight.contains(id) else { return }
        readRequestInFlight.insert(id)
        Task { [weak self] in
            do {
                _ = try await self?.apiClient.markEncounterAsRead(id: id)
                await MainActor.run {
                    self?.markedReadEncounterIDs.insert(id)
                    self?.readRequestInFlight.remove(id)
                }
            } catch {
                await MainActor.run {
                    self?.readRequestInFlight.remove(id)
                }
            }
        }
    }

    func postLocation(lat: Double, lng: Double, accuracyM: Double, recordedAt: Date = Date()) {
        guard !isPostingLocation else { return }
        isPostingLocation = true
        locationPostMessage = nil
        locationPostErrorMessage = nil

        Task { [weak self] in
            do {
                let response = try await self?.apiClient.postLocation(
                    PostLocationRequest(
                        accuracyM: accuracyM,
                        lat: lat,
                        lng: lng,
                        recordedAt: recordedAt
                    )
                )
                await MainActor.run {
                    let count = response?.encounterCount ?? 0
                    self?.lastLocationEncounterCount = count
                    self?.locationPostMessage = "位置情報を送信しました（新規\(count)件）"
                    self?.locationPostErrorMessage = nil
                    self?.isPostingLocation = false
                }
            } catch {
                await MainActor.run {
                    self?.locationPostErrorMessage = "位置情報の送信に失敗しました"
                    self?.isPostingLocation = false
                }
            }
        }
    }

    func submitLyric(encounterId: String, content: String) async throws -> BackendLyricSubmitResponse {
        let response = try await apiClient.submitLyric(encounterId: encounterId, content: content)
        if let index = encounters.firstIndex(where: { $0.id == encounterId }) {
            let encounter = encounters[index]
            encounters[index] = Encounter(
                id: encounter.id,
                userName: encounter.userName,
                track: encounter.track,
                relativeTime: encounter.relativeTime,
                lyric: content,
                occurredAt: encounter.occurredAt
            )
        }
        latestLyricChain = response.chain
        latestLyricSubmission = LatestLyricSubmission(chain: response.chain, content: content)
        return response
    }

    func clearLatestLyricSubmission() {
        latestLyricSubmission = nil
    }

    func clearLatestLyricSubmission(for chainID: String) {
        guard latestLyricSubmission?.chain.id == chainID else { return }
        latestLyricSubmission = nil
    }

    func syncLatestLyricSubmission(with chain: BackendChainDetail) {
        guard latestLyricSubmission?.chain.id == chain.id else { return }

        let normalizedStatus = chain.status.lowercased()
        if normalizedStatus == "completed" || normalizedStatus == "failed" {
            latestLyricSubmission = nil
            latestLyricChain = nil
            return
        }

        let updatedChain = BackendLyricChainSummary(
            id: chain.id,
            participantCount: chain.participantCount,
            status: chain.status,
            threshold: chain.threshold
        )
        latestLyricChain = updatedChain
        if let current = latestLyricSubmission {
            latestLyricSubmission = LatestLyricSubmission(chain: updatedChain, content: current.content)
        }
    }

    func setBLEEnabled(_ isEnabled: Bool) {
        bleSettingsUpdateTask?.cancel()
        bleSettingsRequestVersion += 1
        let currentVersion = bleSettingsRequestVersion
        let previousValue = bleEnabled

        bleEnabled = isEnabled
        applyBLEState()
        isUpdatingBLE = true
        settingsErrorMessage = nil

        bleSettingsUpdateTask = Task { [weak self] in
            guard let self else { return }
            do {
                let settings = try await apiClient.patchMySettings(
                    UpdateUserSettingsRequest(bleEnabled: isEnabled)
                )
                await MainActor.run {
                    guard self.bleSettingsRequestVersion == currentVersion else { return }
                    self.applySettings(settings)
                    self.isUpdatingBLE = false
                    self.bleSettingsUpdateTask = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard self.bleSettingsRequestVersion == currentVersion else { return }
                    self.isUpdatingBLE = false
                    self.bleSettingsUpdateTask = nil
                }
            } catch {
                await MainActor.run {
                    guard self.bleSettingsRequestVersion == currentVersion else { return }
                    self.settingsErrorMessage = "BLE設定の更新に失敗しました。"
                    self.bleEnabled = previousValue
                    self.applyBLEState()
                    self.isUpdatingBLE = false
                    self.bleSettingsUpdateTask = nil
                }
            }
        }
    }

    func updateEncounterSettings(detectionDistance: Int, profileVisible: Bool) {
        encounterSettingsUpdateTask?.cancel()
        encounterSettingsRequestVersion += 1
        let currentVersion = encounterSettingsRequestVersion
        let previousDistance = self.detectionDistance
        let previousVisibility = self.profileVisible

        self.detectionDistance = detectionDistance
        self.profileVisible = profileVisible
        self.isUpdatingEncounterSettings = true
        self.settingsErrorMessage = nil

        encounterSettingsUpdateTask = Task { [weak self] in
            guard let self else { return }
            do {
                let settings = try await apiClient.patchMySettings(
                    UpdateUserSettingsRequest(
                        detectionDistance: detectionDistance,
                        profileVisible: profileVisible
                    )
                )
                await MainActor.run {
                    guard self.encounterSettingsRequestVersion == currentVersion else { return }
                    self.applySettings(settings)
                    self.isUpdatingEncounterSettings = false
                    self.encounterSettingsUpdateTask = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard self.encounterSettingsRequestVersion == currentVersion else { return }
                    self.isUpdatingEncounterSettings = false
                    self.encounterSettingsUpdateTask = nil
                }
            } catch {
                await MainActor.run {
                    guard self.encounterSettingsRequestVersion == currentVersion else { return }
                    self.settingsErrorMessage = "すれ違い設定の更新に失敗しました。"
                    self.detectionDistance = previousDistance
                    self.profileVisible = previousVisibility
                    self.isUpdatingEncounterSettings = false
                    self.encounterSettingsUpdateTask = nil
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
                    #if DEBUG
                    print("[BLEAppCoordinator] latest detection token=\(detection.token) rssi=\(detection.rssi)")
                    #endif
                    await backendClient.enqueueEncounter(
                        targetBLEToken: detection.token,
                        rssi: detection.rssi,
                        occurredAt: detection.detectedAt
                    )

                    do {
                        let user = try await backendClient.fetchUser(forBLEToken: detection.token)
                        await MainActor.run {
                            #if DEBUG
                            print("[BLEAppCoordinator] resolved detected user id=\(user.id) name=\(user.displayName)")
                            #endif
                            self?.latestDetectedUser = user
                        }
                    } catch {
                        #if DEBUG
                        print("[BLEAppCoordinator] failed to resolve detected user token=\(detection.token) error=\(error)")
                        #endif
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
        if isLoadingEncounters {
            return
        }

        await MainActor.run {
            isLoadingEncounters = true
        }

        do {
            let response = try await apiClient.listEncounters(limit: 50)
            let mappedEncounters = response.encounters.map(Self.makeEncounter(from:))
            await MainActor.run {
                let existingLyrics = Dictionary(
                    uniqueKeysWithValues: encounters.compactMap { encounter in
                        encounter.lyric.isEmpty ? nil : (encounter.id, encounter.lyric)
                    }
                )
                let mergedEncounters = mappedEncounters.map { encounter in
                    if !encounter.lyric.isEmpty {
                        return encounter
                    }
                    guard let lyric = existingLyrics[encounter.id] else { return encounter }
                    return Encounter(
                        id: encounter.id,
                        userName: encounter.userName,
                        track: encounter.track,
                        relativeTime: encounter.relativeTime,
                        lyric: lyric,
                        occurredAt: encounter.occurredAt
                    )
                }
                encounters = mergedEncounters
                encounterErrorMessage = nil
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
            lyric: item.lyric ?? "",
            occurredAt: item.occurredAt
        )
    }

    private static func makeTrack(from item: BackendEncounterTrack?) -> Track {
        guard let item else {
            return Track(
                title: "曲情報なし",
                artist: "Unknown Artist",
                color: PrototypeTheme.surfaceElevated,
                artwork: nil
            )
        }

        return Track(
            title: item.title,
            artist: item.artistName,
            color: colorSeed(for: item.title + item.artistName),
            artwork: item.artworkURL
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
