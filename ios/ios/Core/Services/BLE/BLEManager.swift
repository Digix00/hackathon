import Combine
import CoreBluetooth
import Foundation

/// BLE token exchange manager based on docs/architecture/ble.md.
///
/// - Uses non-connectable advertising + scanning only (no GATT connection).
/// - Exchanges only ephemeral BLE token via service UUID advertising payload.
/// - Applies client-side RSSI / detection-count / debounce / cooldown filters before surfacing detections.
/// - Foreground requires two detections within 30 seconds; background accepts a single stronger detection.
final class BLEManager: NSObject, ObservableObject {
    struct Constants {
        static let appServiceUUID = CBUUID(string: "00001234-0000-1000-8000-00805F9B34FB")
        static let tokenPrefixHex = "A17E1E50B1ECAFE0"
        static let foregroundRSSIThreshold = -85
        static let backgroundRSSIThreshold = -80
        static let foregroundDetectionCountThreshold = 2
        static let backgroundDetectionCountThreshold = 1
        static let detectionWindow: TimeInterval = 30
        static let debounce: TimeInterval = 30
        static let cooldown: TimeInterval = 5 * 60
        static let centralRestoreIdentifier = "hackathon-ble-central"
        static let peripheralRestoreIdentifier = "hackathon-ble-peripheral"
    }

    enum BLEState: Equatable {
        case unknown
        case unsupported
        case unauthorized
        case poweredOff
        case poweredOn
    }

    struct Detection: Equatable {
        let token: String
        let rssi: Int
        let detectedAt: Date
    }

    @Published private(set) var state: BLEState = .unknown
    @Published private(set) var latestDetection: Detection?
    @Published private(set) var isAdvertising = false
    @Published private(set) var isScanning = false

    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!

    private var shouldAdvertise = false
    private var shouldScan = false
    private var isForeground = true
    private var lowPowerModeObserver: NSObjectProtocol?
    private var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    private var advertisedToken: String?
    private var advertisedTokenUUID: CBUUID?

    private var detectionCountsByToken: [String: DetectionCounter] = [:]
    private var debounceByToken: [String: Date] = [:]
    private var cooldownByToken: [String: Date] = [:]

    override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionRestoreIdentifierKey: Constants.centralRestoreIdentifier]
        )
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: .main,
            options: [CBPeripheralManagerOptionRestoreIdentifierKey: Constants.peripheralRestoreIdentifier]
        )
        lowPowerModeObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePowerModeChange()
        }
    }

    deinit {
        if let lowPowerModeObserver {
            NotificationCenter.default.removeObserver(lowPowerModeObserver)
        }
        stopScanning()
        stopAdvertising()
    }

    func startAdvertising(token: String) {
        guard let payload = makeAdvertisingPayload(token: token) else { return }

        shouldAdvertise = true
        advertisedToken = payload.backendToken
        advertisedTokenUUID = payload.tokenUUID
        applyAdvertisingState()
    }

    func stopAdvertising() {
        shouldAdvertise = false
        stopAdvertisingRuntime()
    }

    func startScanning() {
        shouldScan = true
        reconfigureScanningPolicy()
    }

    func stopScanning() {
        shouldScan = false
        stopScanningRuntime()
    }

    func updateAppForegroundState(_ isForeground: Bool) {
        self.isForeground = isForeground
        reconfigureScanningPolicy()
    }

    private func stopScanningRuntime() {
        guard centralManager.state == .poweredOn else {
            isScanning = false
            return
        }
        centralManager.stopScan()
        isScanning = false
    }

    private func startScanningRuntimeIfPossible() {
        guard shouldScan, centralManager.state == .poweredOn else {
            stopScanningRuntime()
            return
        }
        guard !isScanning else { return }

        centralManager.scanForPeripherals(
            withServices: [Constants.appServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
    }

    private func updateState(_ centralState: CBManagerState) {
        switch centralState {
        case .unknown, .resetting:
            state = .unknown
        case .unsupported:
            state = .unsupported
        case .unauthorized:
            state = .unauthorized
        case .poweredOff:
            state = .poweredOff
        case .poweredOn:
            state = .poweredOn
        @unknown default:
            state = .unknown
        }
    }

    private func stopAdvertisingRuntime() {
        guard peripheralManager.state == .poweredOn else {
            isAdvertising = false
            return
        }
        peripheralManager.stopAdvertising()
        isAdvertising = false
    }

    private func applyAdvertisingState() {
        guard
            shouldAdvertise,
            !isLowPowerModeEnabled,
            peripheralManager.state == .poweredOn,
            advertisedToken != nil,
            let tokenUUID = advertisedTokenUUID
        else {
            stopAdvertisingRuntime()
            return
        }

        let data: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [Constants.appServiceUUID, tokenUUID]
        ]

        peripheralManager.stopAdvertising()
        peripheralManager.startAdvertising(data)
    }

    private func reconfigureScanningPolicy() {
        guard shouldScan, !isLowPowerModeEnabled else {
            stopScanningRuntime()
            return
        }

        startScanningRuntimeIfPossible()
    }

    private func handlePowerModeChange() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        applyAdvertisingState()
        reconfigureScanningPolicy()
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[BLEManager] \(message)")
        #endif
    }

    private func makeAdvertisingPayload(token: String) -> AdvertisingPayload? {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedToken.isEmpty else { return nil }

        // Token must be 8-byte (16 hex chars), embed it as APP_PREFIX(8 bytes) + TOKEN(8 bytes).
        guard normalizedToken.count == 16, normalizedToken.range(of: "^[0-9a-f]{16}$", options: .regularExpression) != nil else {
            return nil
        }
        guard let tokenUUIDString = makeTokenUUIDString(fromHex8Bytes: normalizedToken) else { return nil }

        return AdvertisingPayload(backendToken: normalizedToken, tokenUUID: CBUUID(string: tokenUUIDString))
    }

    private func makeTokenUUIDString(fromHex8Bytes tokenHex: String) -> String? {
        let fullHex = Constants.tokenPrefixHex + tokenHex
        guard fullHex.count == 32 else { return nil }
        return [
            String(fullHex.prefix(8)),
            String(fullHex.dropFirst(8).prefix(4)),
            String(fullHex.dropFirst(12).prefix(4)),
            String(fullHex.dropFirst(16).prefix(4)),
            String(fullHex.dropFirst(20).prefix(12))
        ].joined(separator: "-")
    }

    private func decodeToken(fromAdvertisementData advertisementData: [String: Any]) -> String? {
        let primaryUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        let overflowUUIDs = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] ?? []
        let serviceUUIDs = primaryUUIDs + overflowUUIDs

        guard serviceUUIDs.contains(Constants.appServiceUUID) else {
            return nil
        }

        guard let tokenUUID = serviceUUIDs.first(where: { $0 != Constants.appServiceUUID }) else {
            return nil
        }

        return decodeBackendToken(fromTokenUUID: tokenUUID)
    }

    private func decodeBackendToken(fromTokenUUID tokenUUID: CBUUID) -> String {
        let normalized = tokenUUID.uuidString.lowercased()
        let compact = normalized.replacingOccurrences(of: "-", with: "")
        let expectedPrefix = Constants.tokenPrefixHex.lowercased()

        // If this UUID was built from APP_PREFIX + 8-byte token, restore hex token.
        if compact.count == 32, compact.hasPrefix(expectedPrefix) {
            return String(compact.suffix(16))
        }

        // Otherwise treat it as canonical UUID token.
        return normalized
    }

    private func shouldEmitDetection(token: String, rssi: NSNumber, now: Date) -> Bool {
        let rssiValue = rssi.intValue
        // CoreBluetooth uses 127 as a sentinel for unavailable RSSI.
        guard rssiValue != 127 else { return false }
        let rssiThreshold = isForeground
            ? Constants.foregroundRSSIThreshold
            : Constants.backgroundRSSIThreshold
        guard rssiValue >= rssiThreshold else { return false }

        let detectionThreshold = isForeground
            ? Constants.foregroundDetectionCountThreshold
            : Constants.backgroundDetectionCountThreshold

        let previousCounter = detectionCountsByToken[token]
        let nextCount: Int
        if let previousCounter, now.timeIntervalSince(previousCounter.windowStartedAt) <= Constants.detectionWindow {
            nextCount = previousCounter.count + 1
        } else {
            nextCount = 1
        }
        detectionCountsByToken[token] = DetectionCounter(count: nextCount, windowStartedAt: now)
        guard nextCount >= detectionThreshold else { return false }

        if isForeground {
            if let last = debounceByToken[token], now.timeIntervalSince(last) < Constants.debounce {
                return false
            }
        }
        if let last = cooldownByToken[token], now.timeIntervalSince(last) < Constants.cooldown {
            return false
        }

        if isForeground {
            debounceByToken[token] = now
        } else {
            debounceByToken.removeValue(forKey: token)
        }
        cooldownByToken[token] = now
        detectionCountsByToken[token] = DetectionCounter(count: 0, windowStartedAt: now)
        return true
    }

    func resetCooldownCache() {
        detectionCountsByToken.removeAll()
        debounceByToken.removeAll()
        cooldownByToken.removeAll()
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateState(central.state)
        reconfigureScanningPolicy()
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        log("Central state restored: \(dict.keys.sorted())")

        if let restoredScanServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID],
           restoredScanServices.contains(Constants.appServiceUUID) {
            shouldScan = true
        }

        reconfigureScanningPolicy()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard let token = decodeToken(fromAdvertisementData: advertisementData) else { return }
        guard token != advertisedToken else { return }

        let now = Date()
        guard shouldEmitDetection(token: token, rssi: RSSI, now: now) else { return }

        latestDetection = Detection(token: token, rssi: RSSI.intValue, detectedAt: now)
    }
}

private struct AdvertisingPayload {
    let backendToken: String
    let tokenUUID: CBUUID
}

private struct DetectionCounter {
    let count: Int
    let windowStartedAt: Date
}

extension BLEManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            log("Advertising failed: \(error.localizedDescription)")
            isAdvertising = false
            return
        }
        isAdvertising = true
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        applyAdvertisingState()
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        log("Peripheral state restored: \(dict.keys.sorted())")

        if let restoredAdvertisement = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey] as? [String: Any],
           let restoredUUIDs = restoredAdvertisement[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
           let restoredTokenUUID = restoredUUIDs.first(where: { $0 != Constants.appServiceUUID }) {
            shouldAdvertise = true
            advertisedTokenUUID = restoredTokenUUID
            advertisedToken = decodeBackendToken(fromTokenUUID: restoredTokenUUID)
        }

        applyAdvertisingState()
    }
}

#if DEBUG
extension BLEManager {
    struct TestAdvertisingPayload: Equatable {
        let backendToken: String
        let tokenUUID: CBUUID
    }

    func _test_makeAdvertisingPayload(token: String) -> TestAdvertisingPayload? {
        guard let payload = makeAdvertisingPayload(token: token) else { return nil }
        return TestAdvertisingPayload(backendToken: payload.backendToken, tokenUUID: payload.tokenUUID)
    }

    func _test_decodeToken(fromAdvertisementData advertisementData: [String: Any]) -> String? {
        decodeToken(fromAdvertisementData: advertisementData)
    }

    func _test_shouldEmitDetection(token: String, rssi: NSNumber, now: Date) -> Bool {
        shouldEmitDetection(token: token, rssi: rssi, now: now)
    }

    func _test_resetCaches() {
        resetCooldownCache()
    }
}
#endif
