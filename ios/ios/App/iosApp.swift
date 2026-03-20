import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct iosApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var appDelegate
    @StateObject private var bleCoordinator = BLEAppCoordinator()
    @StateObject private var pushManager = PushNotificationManager.shared

    init() {
#if canImport(FirebaseCore)
        FirebaseApp.configure()
#endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .prototypeTypography()
                .environmentObject(bleCoordinator)
                .environmentObject(bleCoordinator.bleManager)
                .environmentObject(pushManager)
                .onOpenURL { url in
                    _ = GoogleSignInCoordinator.handle(url: url)
                }
                .task {
                    bleCoordinator.startIfNeeded(scenePhase: scenePhase)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    bleCoordinator.updateScenePhase(newPhase)
                }
        }
    }
}
