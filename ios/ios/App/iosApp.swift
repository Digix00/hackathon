import SwiftUI

@main
struct iosApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var appDelegate
    @StateObject private var bleCoordinator = BLEAppCoordinator()
    @StateObject private var pushManager = PushNotificationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .prototypeTypography()
                .environmentObject(bleCoordinator)
                .environmentObject(bleCoordinator.bleManager)
                .environmentObject(pushManager)
                .task {
                    bleCoordinator.startIfNeeded(scenePhase: scenePhase)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    bleCoordinator.updateScenePhase(newPhase)
                }
        }
    }
}
