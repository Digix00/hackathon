import UIKit
import UserNotifications

#if canImport(FirebaseCore)
import FirebaseCore
#endif

final class NotificationAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
#if canImport(FirebaseCore)
        configureFirebaseIfNeeded()
#endif
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        PushNotificationManager.shared.handleDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        PushNotificationManager.shared.handleRegistrationError(error)
    }

#if canImport(FirebaseCore)
    private func configureFirebaseIfNeeded() {
        guard FirebaseApp.app() == nil else { return }

        if let googleServiceInfoPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           FileManager.default.fileExists(atPath: googleServiceInfoPath) {
            FirebaseApp.configure()
            return
        }

        guard let options = firebaseOptionsFromInfoDictionary() else { return }
        FirebaseApp.configure(options: options)
    }

    private func firebaseOptionsFromInfoDictionary() -> FirebaseOptions? {
        guard
            let apiKey = infoValue("FIREBASE_API_KEY"),
            let appID = infoValue("FIREBASE_APP_ID"),
            let senderID = infoValue("FIREBASE_GCM_SENDER_ID"),
            let projectID = infoValue("FIREBASE_PROJECT_ID")
        else {
            return nil
        }

        let options = FirebaseOptions(googleAppID: appID, gcmSenderID: senderID)
        options.apiKey = apiKey
        options.projectID = projectID
        options.storageBucket = infoValue("FIREBASE_STORAGE_BUCKET")
        options.clientID = infoValue("GOOGLE_CLIENT_ID")
        return options
    }

    private func infoValue(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isInvalidFirebaseInfoValue(trimmed) else {
            return nil
        }
        return trimmed
    }

    private func isInvalidFirebaseInfoValue(_ value: String) -> Bool {
        if value.isEmpty || value == "demo" || value.hasPrefix("YOUR_") {
            return true
        }

        // Treat unresolved build setting placeholders as missing configuration.
        return value.hasPrefix("$(") && value.hasSuffix(")")
    }
#endif
}
