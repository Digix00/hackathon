import SwiftUI

@main
struct iosApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var bleCoordinator = BLEAppCoordinator()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .prototypeTypography()
                .environmentObject(bleCoordinator)
                .environmentObject(bleCoordinator.bleManager)
                .task {
                    bleCoordinator.startIfNeeded(scenePhase: scenePhase)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    bleCoordinator.updateScenePhase(newPhase)
                }
        }
    }
}
