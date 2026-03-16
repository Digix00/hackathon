import Combine
import CoreBluetooth
import Foundation

/// BLE token exchange manager based on docs/architecture/ble.md.
///
/// - Uses non-connectable advertising + scanning only (no GATT connection).
/// - Exchanges only ephemeral BLE token via advertising payload.
/// - Applies client-side cooldown and RSSI filtering before surfacing detections.
final class BLEManager: NSObject, ObservableObject {
    struct Constants {
        static let manufacturerID: UInt16 = 0xD1A1

        static let scanWindow: TimeInterval = 2
        static let scanInterval: TimeInterval = 5
        static let rssiThreshold = -90
        static let cooldown: TimeInterval = 5 * 60
        static let maxTokenLength = 16
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
    private var advertisedToken: String?

    private var scanCycleTimer: Timer?
    private var scanWindowStopTimer: Timer?

    private var cooldownByToken: [String: Date] = [:]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        peripheralManager = CBPeripheralManager(delegate: self, queue: .main)
    }

    deinit {
        stopScanning()
        stopAdvertising()
    }

    func startAdvertising(token: String) {
        let sanitized = sanitize(token: token)
        guard !sanitized.isEmpty else { return }

        shouldAdvertise = true
        advertisedToken = sanitized
        applyAdvertisingState()
    }

    func stopAdvertising() {
        shouldAdvertise = false
        stopAdvertisingRuntime()
    }

    func startScanning() {
        shouldScan = true
        applyScanningState()
    }

    func stopScanning() {
        shouldScan = false
        stopScanningRuntime()
    }

    private func stopScanningRuntime() {
        scanCycleTimer?.invalidate()
        scanCycleTimer = nil

        scanWindowStopTimer?.invalidate()
        scanWindowStopTimer = nil

        centralManager.stopScan()
        isScanning = false
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
        guard shouldAdvertise, peripheralManager.state == .poweredOn, let token = advertisedToken else {
            stopAdvertisingRuntime()
            return
        }

        let manufacturerData = buildManufacturerData(token: token)
        let data: [String: Any] = [
            CBAdvertisementDataManufacturerDataKey: manufacturerData,
            CBAdvertisementDataIsConnectable: false
        ]

        peripheralManager.stopAdvertising()
        peripheralManager.startAdvertising(data)
        isAdvertising = true
    }

    private func applyScanningState() {
        guard shouldScan, centralManager.state == .poweredOn else {
            stopScanningRuntime()
            return
        }
        guard !isScanning else { return }

        isScanning = true
        startScanWindow()

        let repeatEvery = Constants.scanInterval
        scanCycleTimer = Timer.scheduledTimer(withTimeInterval: repeatEvery, repeats: true) { [weak self] _ in
            self?.startScanWindow()
        }
    }

    private func startScanWindow() {
        guard centralManager.state == .poweredOn else {
            stopScanningRuntime()
            return
        }

        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )

        scanWindowStopTimer?.invalidate()
        scanWindowStopTimer = Timer.scheduledTimer(withTimeInterval: Constants.scanWindow, repeats: false) { [weak self] _ in
            self?.centralManager.stopScan()
        }
    }

    private func sanitize(token: String) -> String {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let compact = String(trimmed.prefix(Constants.maxTokenLength))
        return compact
    }

    private func buildManufacturerData(token: String) -> Data {
        var bytes: [UInt8] = [
            UInt8(Constants.manufacturerID & 0x00FF),
            UInt8((Constants.manufacturerID & 0xFF00) >> 8)
        ]
        bytes.append(contentsOf: token.utf8)
        return Data(bytes)
    }

    private func decodeToken(fromAdvertisementData advertisementData: [String: Any]) -> String? {
        return decodeToken(fromManufacturerData: advertisementData)
    }

    private func decodeToken(fromManufacturerData advertisementData: [String: Any]) -> String? {
        guard
            let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
            manufacturerData.count > MemoryLayout<UInt16>.size
        else {
            return nil
        }

        let id = UInt16(manufacturerData[0]) | (UInt16(manufacturerData[1]) << 8)
        guard id == Constants.manufacturerID else { return nil }

        let payload = manufacturerData.dropFirst(MemoryLayout<UInt16>.size)
        let token = String(data: payload, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let token, !token.isEmpty else { return nil }
        return token
    }

    private func shouldEmitDetection(token: String, rssi: NSNumber, now: Date) -> Bool {
        let rssiValue = rssi.intValue
        // CoreBluetooth uses 127 as a sentinel for unavailable RSSI.
        guard rssiValue != 127 else { return false }
        guard rssiValue >= Constants.rssiThreshold else { return false }

        if let last = cooldownByToken[token], now.timeIntervalSince(last) < Constants.cooldown {
            return false
        }

        cooldownByToken[token] = now
        return true
    }

    func resetCooldownCache() {
        cooldownByToken.removeAll()
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateState(central.state)
        applyScanningState()
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
