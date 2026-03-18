import SwiftUI

@MainActor
final class UserSettingsViewModel: ObservableObject {
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
    private var notificationEnabled = true
    private var loadTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
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
        let previous = detectionDistance
        detectionDistance = Double(clamped)

        submitUpdate(
            UpdateUserSettingsRequest(detectionDistance: clamped),
            revert: { self.detectionDistance = previous }
        )
    }

    func setProfileVisible(_ isVisible: Bool) {
        let previous = isProfileVisible
        isProfileVisible = isVisible

        submitUpdate(
            UpdateUserSettingsRequest(profileVisible: isVisible),
            revert: { self.isProfileVisible = previous }
        )
    }

    func setEncounterNotifications(_ isEnabled: Bool) {
        let previousEncounter = encounterNotificationEnabled
        let previousGlobal = notificationEnabled

        encounterNotificationEnabled = isEnabled
        let newGlobal = isEnabled || generatedNotificationEnabled
        notificationEnabled = newGlobal

        submitUpdate(
            UpdateUserSettingsRequest(
                notificationEnabled: newGlobal,
                encounterNotificationEnabled: isEnabled
            ),
            revert: {
                self.encounterNotificationEnabled = previousEncounter
                self.notificationEnabled = previousGlobal
            }
        )
    }

    func setGeneratedNotifications(_ isEnabled: Bool) {
        let previousBatch = generatedNotificationEnabled
        let previousGlobal = notificationEnabled

        generatedNotificationEnabled = isEnabled
        let newGlobal = encounterNotificationEnabled || isEnabled
        notificationEnabled = newGlobal

        submitUpdate(
            UpdateUserSettingsRequest(
                notificationEnabled: newGlobal,
                batchNotificationEnabled: isEnabled
            ),
            revert: {
                self.generatedNotificationEnabled = previousBatch
                self.notificationEnabled = previousGlobal
            }
        )
    }

    func setThemeMode(_ mode: ThemeMode) {
        let previous = themeMode
        themeMode = mode

        submitUpdate(
            UpdateUserSettingsRequest(themeMode: mode.rawValue),
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
            errorMessage = "設定の取得に失敗しました"
            hasLoaded = false
        }
    }

    private func submitUpdate(_ request: UpdateUserSettingsRequest, revert: @escaping () -> Void) {
        saveTask?.cancel()
        saveTask = Task { await performUpdate(request, revert: revert) }
    }

    private func performUpdate(_ request: UpdateUserSettingsRequest, revert: @escaping () -> Void) async {
        activeSaveCount += 1
        isSaving = true
        errorMessage = nil
        defer {
            activeSaveCount = max(0, activeSaveCount - 1)
            isSaving = activeSaveCount > 0
        }

        do {
            let settings = try await client.patchMySettings(request)
            applySettings(settings)
        } catch {
            if Task.isCancelled { return }
            errorMessage = "設定の更新に失敗しました"
            revert()
        }
    }

    private func applySettings(_ settings: BackendUserSettings) {
        detectionDistance = Double(settings.detectionDistance)
        isProfileVisible = settings.profileVisible
        encounterNotificationEnabled = settings.encounterNotificationEnabled
        generatedNotificationEnabled = settings.batchNotificationEnabled
        notificationEnabled = settings.notificationEnabled
        themeMode = ThemeMode(rawValue: settings.themeMode) ?? .system
        hasLoaded = true
    }
}
