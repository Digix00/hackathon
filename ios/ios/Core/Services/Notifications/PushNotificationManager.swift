import Combine
import Foundation
import Security
import UIKit
import UserNotifications

@MainActor
final class PushNotificationManager: NSObject, ObservableObject {
    static let shared = PushNotificationManager()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var lastErrorMessage: String?

    private let apiClient: BackendAPIClient
    private let store: PushTokenStore
    private var desiredEnabled = false

    override init() {
        self.apiClient = BackendAPIClient()
        self.store = PushTokenStore()
        super.init()
        Task { await refreshAuthorizationStatus() }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func handleDeviceToken(_ tokenData: Data) {
        let token = Self.hexString(from: tokenData)
        let previous = store.pushToken
        store.pushToken = token

        guard desiredEnabled else { return }

        if previous == token, store.backendDeviceId != nil {
            return
        }

        Task { await registerOrUpdate(token: token, enabled: true) }
    }

    func handleRegistrationError(_ error: Error) {
        lastErrorMessage = "通知の登録に失敗しました。"
    }

    func applyNotificationPreference(isEnabled: Bool) async {
        desiredEnabled = isEnabled
        if isEnabled {
            let granted = await requestAuthorizationIfNeeded()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
                await updateEnabledState(true)
            } else {
                lastErrorMessage = "通知が許可されていません。設定アプリから許可してください。"
                await updateEnabledState(false)
            }
        } else {
            UIApplication.shared.unregisterForRemoteNotifications()
            await updateEnabledState(false)
        }
    }

    func syncFromSettings(notificationEnabled: Bool) async {
        desiredEnabled = notificationEnabled
        await refreshAuthorizationStatus()

        guard notificationEnabled else {
            await updateEnabledState(false)
            return
        }

        if isAuthorized(authorizationStatus) {
            UIApplication.shared.registerForRemoteNotifications()
            await updateEnabledState(true)
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        await refreshAuthorizationStatus()
        if isAuthorized(authorizationStatus) {
            return true
        }
        if authorizationStatus == .denied {
            return false
        }

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await refreshAuthorizationStatus()
            return granted
        } catch {
            lastErrorMessage = "通知許可の取得に失敗しました。"
            return false
        }
    }

    private func updateEnabledState(_ enabled: Bool) async {
        guard let backendId = store.backendDeviceId else {
            if enabled, let token = store.pushToken {
                await registerOrUpdate(token: token, enabled: true)
            }
            return
        }

        do {
            _ = try await apiClient.patchPushToken(
                id: backendId,
                request: UpdatePushTokenRequest(
                    pushToken: nil,
                    enabled: enabled,
                    appVersion: Self.appVersion
                )
            )
        } catch {
            lastErrorMessage = "通知設定の同期に失敗しました。"
        }
    }

    private func registerOrUpdate(token: String, enabled: Bool) async {
        let request = CreatePushTokenRequest(
            platform: "ios",
            deviceId: store.deviceId,
            pushToken: token,
            appVersion: Self.appVersion
        )

        do {
            let device = try await apiClient.createPushToken(request)
            store.backendDeviceId = device.id

            if !enabled {
                _ = try await apiClient.patchPushToken(
                    id: device.id,
                    request: UpdatePushTokenRequest(
                        pushToken: nil,
                        enabled: false,
                        appVersion: Self.appVersion
                    )
                )
            }
        } catch {
            lastErrorMessage = "通知トークンの登録に失敗しました。"
        }
    }

    private static func hexString(from data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }

    private static var appVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    private func isAuthorized(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }
}

private final class PushTokenStore {
    private enum Key: String {
        case deviceId = "push_device_id"
        case backendDeviceId = "push_backend_device_id"
        case pushToken = "push_token"
    }

    var deviceId: String {
        if let stored = SecureStore.readString(key: Key.deviceId.rawValue) {
            return stored
        }
        let newId = UUID().uuidString
        SecureStore.writeString(newId, key: Key.deviceId.rawValue)
        return newId
    }

    var backendDeviceId: String? {
        get { SecureStore.readString(key: Key.backendDeviceId.rawValue) }
        set {
            if let value = newValue {
                SecureStore.writeString(value, key: Key.backendDeviceId.rawValue)
            } else {
                SecureStore.delete(key: Key.backendDeviceId.rawValue)
            }
        }
    }

    var pushToken: String? {
        get { SecureStore.readString(key: Key.pushToken.rawValue) }
        set {
            if let value = newValue {
                SecureStore.writeString(value, key: Key.pushToken.rawValue)
            } else {
                SecureStore.delete(key: Key.pushToken.rawValue)
            }
        }
    }
}

private enum SecureStore {
    private static let service = Bundle.main.bundleIdentifier ?? "com.digix00.musicswapping.secure"

    static func writeString(_ value: String, key: String) {
        guard let data = value.data(using: .utf8) else { return }
        write(data: data, key: key)
    }

    static func readString(key: String) -> String? {
        guard let data = readData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func write(data: Data, key: String) {
        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]

        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        var addQuery = baseQuery
        addQuery[kSecValueData] = data
        addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func readData(key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }

    static func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
