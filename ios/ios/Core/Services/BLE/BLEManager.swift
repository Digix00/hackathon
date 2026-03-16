import Combine
import CoreBluetooth
import Foundation

/// BLE token exchange manager based on docs/architecture/ble.md.
///
/// - Uses non-connectable advertising + scanning only (no GATT connection).
/// - Exchanges only ephemeral BLE token via service UUID advertising payload.
/// - Applies client-side RSSI / detection-count / debounce / cooldown filters before surfacing detections.
final class BLEManager: NSObject, ObservableObject {
    struct Constants {
        static let appServiceUUID = CBUUID(string: "00001234-0000-1000-8000-00805F9B34FB")
        static let tokenPrefixHex = "A17E1E50B1ECAFE0"
        static let rssiThreshold = -85
        static let detectionCountThreshold = 2
        static let detectionWindow: TimeInterval = 30
        static let debounce: TimeInterval = 30
        static let cooldown: TimeInterval = 5 * 60
        static let backgroundScanWindow: TimeInterval = 5
        static let backgroundSleepInterval: TimeInterval = 10
        static let longBackgroundThreshold: TimeInterval = 10 * 60
        static let longBackgroundScanWindow: TimeInterval = 3
        static let longBackgroundSleepInterval: TimeInterval = 30
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
    private var enteredBackgroundAt: Date?
    private var scanPolicyTask: Task<Void, Never>?
    private var lowPowerModeObserver: NSObjectProtocol?
    private var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    private var advertisedToken: String?
    private var advertisedTokenUUID: CBUUID?

    private var detectionCountsByToken: [String: DetectionCounter] = [:]
    private var debounceByToken: [String: Date] = [:]
    private var cooldownByToken: [String: Date] = [:]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
        lowPowerModeObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePowerModeChange()
        }
    }

    deinit {
        scanPolicyTask?.cancel()
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
        scanPolicyTask?.cancel()
        scanPolicyTask = nil
        stopScanningRuntime()
    }

    func updateAppForegroundState(_ isForeground: Bool) {
        self.isForeground = isForeground
        enteredBackgroundAt = isForeground ? nil : Date()
        reconfigureScanningPolicy()
    }

    private func stopScanningRuntime() {
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
            CBAdvertisementDataServiceUUIDsKey: [Constants.appServiceUUID, tokenUUID],
            CBAdvertisementDataIsConnectable: false
        ]

        peripheralManager.stopAdvertising()
        peripheralManager.startAdvertising(data)
        isAdvertising = true
    }

    private func reconfigureScanningPolicy() {
        scanPolicyTask?.cancel()
        scanPolicyTask = nil

        guard shouldScan, !isLowPowerModeEnabled else {
            stopScanningRuntime()
            return
        }

        if isForeground {
            startScanningRuntimeIfPossible()
            return
        }

        scanPolicyTask = Task { [weak self] in
            await self?.runBackgroundOpportunisticLoop()
        }
    }

    @MainActor
    private func runBackgroundOpportunisticLoop() async {
        while shouldScan, !isForeground, !isLowPowerModeEnabled, !Task.isCancelled {
            let cadence = currentBackgroundCadence()

            startScanningRuntimeIfPossible()
            try? await Task.sleep(nanoseconds: UInt64(cadence.window * 1_000_000_000))

            guard shouldScan, !isForeground, !isLowPowerModeEnabled, !Task.isCancelled else { break }
            stopScanningRuntime()

            try? await Task.sleep(nanoseconds: UInt64(cadence.sleep * 1_000_000_000))
        }

        if !isForeground || isLowPowerModeEnabled || !shouldScan {
            stopScanningRuntime()
        }
    }

    private func currentBackgroundCadence() -> (window: TimeInterval, sleep: TimeInterval) {
        guard
            let enteredBackgroundAt,
            Date().timeIntervalSince(enteredBackgroundAt) >= Constants.longBackgroundThreshold
        else {
            return (Constants.backgroundScanWindow, Constants.backgroundSleepInterval)
        }
        return (Constants.longBackgroundScanWindow, Constants.longBackgroundSleepInterval)
    }

    private func handlePowerModeChange() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        applyAdvertisingState()
        reconfigureScanningPolicy()
    }

    private func makeAdvertisingPayload(token: String) -> AdvertisingPayload? {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedToken.isEmpty else { return nil }

        // 1) If token is already UUID, advertise it directly as TOKEN_UUID.
        if UUID(uuidString: normalizedToken) != nil {
            return AdvertisingPayload(backendToken: normalizedToken, tokenUUID: CBUUID(string: normalizedToken))
        }

        // 2) If token is 8-byte (16 hex chars), embed it as APP_PREFIX(8 bytes) + TOKEN(8 bytes).
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
        guard
            let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
            serviceUUIDs.contains(Constants.appServiceUUID)
        else {
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
        guard rssiValue >= Constants.rssiThreshold else { return false }

        let previousCounter = detectionCountsByToken[token]
        let nextCount: Int
        if let previousCounter, now.timeIntervalSince(previousCounter.windowStartedAt) <= Constants.detectionWindow {
            nextCount = previousCounter.count + 1
        } else {
            nextCount = 1
        }
        detectionCountsByToken[token] = DetectionCounter(count: nextCount, windowStartedAt: now)
        guard nextCount >= Constants.detectionCountThreshold else { return false }

        if let last = debounceByToken[token], now.timeIntervalSince(last) < Constants.debounce {
            return false
        }
        if let last = cooldownByToken[token], now.timeIntervalSince(last) < Constants.cooldown {
            return false
        }

        debounceByToken[token] = now
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
        if error != nil {
            isAdvertising = false
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        applyAdvertisingState()
    }
}
