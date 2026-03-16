import Combine
import CoreMotion
import Foundation

final class MotionManager: ObservableObject {
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0

    private let manager: CMMotionManager

    init() {
        manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
    }

    func startUpdates() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }

        manager.startDeviceMotionUpdates(to: .main) { [weak self] motionData, error in
            guard error == nil, let motionData else { return }
            self?.pitch = motionData.attitude.pitch
            self?.roll = motionData.attitude.roll
        }
    }

    func stopUpdates() {
        guard manager.isDeviceMotionActive else { return }
        manager.stopDeviceMotionUpdates()
    }

    deinit {
        stopUpdates()
    }
}
