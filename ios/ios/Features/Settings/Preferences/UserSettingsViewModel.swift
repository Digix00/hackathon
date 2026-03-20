import Combine
import SwiftUI

@MainActor
final class UserSettingsViewModel: ObservableObject {
    private enum SaveField: Hashable {
        case detectionDistance
        case profileVisible
        case encounterNotification
        case batchNotification
        case notificationEnabled
    }

    @Published var detectionDistance: Double = 50
    @Published var isProfileVisible = true
    @Published var encounterNotificationEnabled = true
    @Published var batchNotificationEnabled = true
    @Published var notificationEnabled = true

    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var hasLoaded = false
    @Published var errorMessage: String?

    private let client: BackendAPIClient
    private let pushManager: PushNotificationManager
    private var confirmedDetectionDistance: Double = 50
    private var loadTask: Task<Void, Never>?
    private var saveTasks: [SaveField: Task<Void, Never>] = [:]
    private var activeSaveCount = 0

    init(
        client: BackendAPIClient = BackendAPIClient(),
        pushManager: PushNotificationManager? = nil
    ) {
        self.client = client
        self.pushManager = pushManager ?? .shared
    }

    func loadIfNeeded() {
        guard !hasLoaded, !isLoading else { return }
        loadTask?.cancel()
        loadTask = Task { await loadSettings() }
    }

    func refresh() {
        loadTask?.cancel()
        loadTask = Task { await loadSettings() }
    }

    func commitDetectionDistance() {
        let rounded = Int(detectionDistance.rounded())
        let clamped = min(max(rounded, 10), 100)
        let previous = confirmedDetectionDistance
        detectionDistance = Double(clamped)

        submitUpdate(
            UpdateUserSettingsRequest(detectionDistance: clamped),
            field: .detectionDistance,
            revert: { self.detectionDistance = previous }
        )
    }

    func setProfileVisible(_ isVisible: Bool) {
        let previous = isProfileVisible
        isProfileVisible = isVisible

        submitUpdate(
            UpdateUserSettingsRequest(profileVisible: isVisible),
            field: .profileVisible,
            revert: { self.isProfileVisible = previous }
        )
    }

    func setEncounterNotifications(_ isEnabled: Bool) {
        let previousEncounter = encounterNotificationEnabled

        encounterNotificationEnabled = isEnabled

        submitUpdate(
            UpdateUserSettingsRequest(
                encounterNotificationEnabled: isEnabled
            ),
            field: .encounterNotification,
            revert: {
                self.encounterNotificationEnabled = previousEncounter
            }
        )
    }

    func setBatchNotifications(_ isEnabled: Bool) {
        let previousBatch = batchNotificationEnabled

        batchNotificationEnabled = isEnabled

        submitUpdate(
            UpdateUserSettingsRequest(
                batchNotificationEnabled: isEnabled
            ),
            field: .batchNotification,
            revert: {
                self.batchNotificationEnabled = previousBatch
            }
        )
    }

    func setNotificationEnabled(_ isEnabled: Bool) {
        let previous = notificationEnabled

        notificationEnabled = isEnabled

        submitUpdate(
            UpdateUserSettingsRequest(notificationEnabled: isEnabled),
            field: .notificationEnabled,
            revert: { self.notificationEnabled = previous }
        )
    }

    private func loadSettings() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let settings = try await client.getMySettings()
            if Task.isCancelled { return }
            applySettings(settings)
        } catch {
            if Task.isCancelled { return }
            errorMessage = "設定の取得に失敗しました"
            hasLoaded = false
        }
    }

    private func submitUpdate(
        _ request: UpdateUserSettingsRequest,
        field: SaveField,
        revert: @escaping () -> Void
    ) {
        loadTask?.cancel()
        saveTasks[field]?.cancel()
        saveTasks[field] = Task { await performUpdate(request, field: field, revert: revert) }
    }

    private func performUpdate(
        _ request: UpdateUserSettingsRequest,
        field: SaveField,
        revert: @escaping () -> Void
    ) async {
        activeSaveCount += 1
        isSaving = true
        errorMessage = nil
        defer {
            activeSaveCount = max(0, activeSaveCount - 1)
            isSaving = activeSaveCount > 0
        }

        do {
            let settings = try await client.patchMySettings(request)
            if Task.isCancelled { return }
            applySettings(settings, updating: request)
            if request.notificationEnabled != nil {
                Task { await pushManager.applyNotificationPreference(isEnabled: settings.notificationEnabled) }
            }
        } catch {
            if Task.isCancelled { return }
            errorMessage = "設定の更新に失敗しました"
            revert()
        }
    }

    private func applySettings(_ settings: BackendUserSettings) {
        detectionDistance = Double(settings.detectionDistance)
        confirmedDetectionDistance = detectionDistance
        isProfileVisible = settings.profileVisible
        encounterNotificationEnabled = settings.encounterNotificationEnabled
        batchNotificationEnabled = settings.batchNotificationEnabled
        notificationEnabled = settings.notificationEnabled
        hasLoaded = true
        Task { await pushManager.syncFromSettings(notificationEnabled: settings.notificationEnabled) }
    }

    private func applySettings(_ settings: BackendUserSettings, updating request: UpdateUserSettingsRequest) {
        if request.detectionDistance != nil {
            detectionDistance = Double(settings.detectionDistance)
            confirmedDetectionDistance = detectionDistance
        }
        if request.profileVisible != nil {
            isProfileVisible = settings.profileVisible
        }
        if request.encounterNotificationEnabled != nil {
            encounterNotificationEnabled = settings.encounterNotificationEnabled
        }
        if request.batchNotificationEnabled != nil {
            batchNotificationEnabled = settings.batchNotificationEnabled
        }
        if request.notificationEnabled != nil {
            notificationEnabled = settings.notificationEnabled
        }
    }
}
