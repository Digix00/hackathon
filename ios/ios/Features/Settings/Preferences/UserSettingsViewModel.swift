import Combine
import SwiftUI

@MainActor
final class UserSettingsViewModel: ObservableObject {
    private enum SaveField: Hashable {
        case detectionDistance
        case profileVisible
        case encounterNotification
        case generatedNotification
        case themeMode
    }

    enum ThemeMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system:
                return "システムに合わせる"
            case .light:
                return "ライトテーマ"
            case .dark:
                return "ダークテーマ"
            }
        }

        var iconName: String {
            switch self {
            case .system:
                return "circle.lefthalf.filled"
            case .light:
                return "sun.max.fill"
            case .dark:
                return "moon.fill"
            }
        }
    }

    @Published var detectionDistance: Double = 50
    @Published var isProfileVisible = true
    @Published var encounterNotificationEnabled = true
    @Published var generatedNotificationEnabled = true
    @Published var themeMode: ThemeMode = .system

    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var hasLoaded = false
    @Published var errorMessage: String?

    private let client: BackendAPIClient
    private var confirmedDetectionDistance: Double = 50
    private var notificationEnabled = true
    private var loadTask: Task<Void, Never>?
    private var saveTasks: [SaveField: Task<Void, Never>] = [:]
    private var activeSaveCount = 0

    init(client: BackendAPIClient = BackendAPIClient()) {
        self.client = client
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

    func setGeneratedNotifications(_ isEnabled: Bool) {
        let previousBatch = generatedNotificationEnabled

        generatedNotificationEnabled = isEnabled

        submitUpdate(
            UpdateUserSettingsRequest(
                batchNotificationEnabled: isEnabled
            ),
            field: .generatedNotification,
            revert: {
                self.generatedNotificationEnabled = previousBatch
            }
        )
    }

    func setThemeMode(_ mode: ThemeMode) {
        let previous = themeMode
        themeMode = mode

        submitUpdate(
            UpdateUserSettingsRequest(themeMode: mode.rawValue),
            field: .themeMode,
            revert: { self.themeMode = previous }
        )
    }

    private func loadSettings() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let settings = try await client.getMySettings()
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
        generatedNotificationEnabled = settings.batchNotificationEnabled
        notificationEnabled = settings.notificationEnabled
        themeMode = ThemeMode(rawValue: settings.themeMode) ?? .system
        hasLoaded = true
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
            generatedNotificationEnabled = settings.batchNotificationEnabled
        }
        if request.notificationEnabled != nil {
            notificationEnabled = settings.notificationEnabled
        }
        if request.themeMode != nil {
            themeMode = ThemeMode(rawValue: settings.themeMode) ?? .system
        }
        hasLoaded = true
    }
}
