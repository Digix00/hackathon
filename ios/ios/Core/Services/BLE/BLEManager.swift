import Combine
import CoreBluetooth
import Foundation

/// BLE token exchange manager using GATT connections for reliable background operation.
///
/// - Uses GATT connection-based approach (CBCentralManager + CBPeripheralManager).
/// - Peripheral advertises a service and exposes token via characteristic.
/// - Central scans, connects, reads token from characteristic, then disconnects.
/// - Supports state restoration for background operation continuity.
final class BLEManager: NSObject, ObservableObject {
    struct Constants {
        static let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
        static let characteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")
        static let centralRestoreIdentifier = "hackathon-ble-central"
        static let peripheralRestoreIdentifier = "hackathon-ble-peripheral"

        // Detection filters
        static let encounterCooldown: TimeInterval = 5 * 60 // 5 minutes
        static let debounce: TimeInterval = 30 // 30 seconds
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
    private var characteristic: CBMutableCharacteristic?

    // Connection management
    private var connectedPeripherals: Set<CBPeripheral> = []

    // Detection deduplication
    private var cooldownByToken: [String: Date] = [:]
    private var debounceByToken: [String: Date] = [:]

    override init() {
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: Constants.centralRestoreIdentifier]
        )
        peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionRestoreIdentifierKey: Constants.peripheralRestoreIdentifier]
        )
    }

    deinit {
        stopScanning()
        stopAdvertising()
    }

    func startAdvertising(token: String) {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        log("startAdvertising called with token: \(token) -> normalized: \(normalizedToken)")
        guard !normalizedToken.isEmpty else {
            log("Token is empty, ignoring")
            return
        }

        shouldAdvertise = true
        advertisedToken = normalizedToken
        log("Set advertisedToken to: \(normalizedToken)")
        applyAdvertisingState()
    }

    func stopAdvertising() {
        shouldAdvertise = false
        stopAdvertisingRuntime()
    }

    func startScanning() {
        shouldScan = true
        startScanningRuntimeIfPossible()
    }

    func stopScanning() {
        shouldScan = false
        stopScanningRuntime()
    }

    func updateAppForegroundState(_ isForeground: Bool) {
        // GATT-based approach works in both foreground and background
        // No special handling needed
    }

    func resetCooldownCache() {
        cooldownByToken.removeAll()
        debounceByToken.removeAll()
    }

    private func stopScanningRuntime() {
        guard centralManager.state == .poweredOn else {
            isScanning = false
            return
        }
        centralManager.stopScan()

        // Disconnect all connected peripherals
        for peripheral in connectedPeripherals {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals.removeAll()

        isScanning = false
    }

    private func startScanningRuntimeIfPossible() {
        guard shouldScan, centralManager.state == .poweredOn else {
            stopScanningRuntime()
            return
        }
        guard !isScanning else { return }

        // Scan for peripherals advertising our service
        // Allow duplicates is false to reduce overhead, we'll reconnect after cooldown
        centralManager.scanForPeripherals(
            withServices: [Constants.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        isScanning = true
        log("Started scanning for peripherals")
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
        log("applyAdvertisingState called: shouldAdvertise=\(shouldAdvertise), peripheralState=\(peripheralManager.state.rawValue), advertisedToken=\(advertisedToken ?? "nil")")

        guard
            shouldAdvertise,
            peripheralManager.state == .poweredOn,
            let token = advertisedToken
        else {
            log("Advertising conditions not met, stopping")
            stopAdvertisingRuntime()
            return
        }

        // Create characteristic with dynamic read
        let characteristic = CBMutableCharacteristic(
            type: Constants.characteristicUUID,
            properties: [.read],
            value: nil, // Dynamic read
            permissions: [.readable]
        )
        self.characteristic = characteristic

        // Create service
        let service = CBMutableService(type: Constants.serviceUUID, primary: true)
        service.characteristics = [characteristic]

        // Remove existing services and add new one
        peripheralManager.removeAllServices()
        peripheralManager.add(service)

        // Start advertising
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [Constants.serviceUUID],
            CBAdvertisementDataLocalNameKey: "Hackathon"
        ])

        log("Started advertising with token: \(token)")
    }

    private func shouldEmitDetection(token: String, now: Date) -> Bool {
        // Exclude self
        guard token != advertisedToken else {
            log("Ignore detection: self token")
            return false
        }

        // Check debounce (prevent rapid re-detection)
        if let lastDebounce = debounceByToken[token],
           now.timeIntervalSince(lastDebounce) < Constants.debounce {
            log("Ignore detection token=\(token) reason=debounce")
            return false
        }

        // Check cooldown (prevent detection within cooldown period)
        if let lastCooldown = cooldownByToken[token],
           now.timeIntervalSince(lastCooldown) < Constants.encounterCooldown {
            log("Ignore detection token=\(token) reason=cooldown")
            return false
        }

        // Update debounce and cooldown
        debounceByToken[token] = now
        cooldownByToken[token] = now

        log("Emit detection token=\(token)")
        return true
    }

    private func processEncounter(token: String, rssi: Int?) {
        let now = Date()
        guard shouldEmitDetection(token: token, now: now) else { return }

        DispatchQueue.main.async {
            self.latestDetection = Detection(
                token: token,
                rssi: rssi ?? 0,
                detectedAt: now
            )
        }
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[BLEManager] \(message)")
        #endif
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateState(central.state)
        log("Central state updated: \(central.state.rawValue)")

        if central.state == .poweredOn && shouldScan {
            startScanningRuntimeIfPossible()
        } else {
            stopScanningRuntime()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // Avoid duplicate connections
        guard !connectedPeripherals.contains(peripheral) else {
            log("Skip connection: already connected to \(peripheral.identifier)")
            return
        }

        log("Discovered peripheral: \(peripheral.identifier), RSSI: \(RSSI)")

        connectedPeripherals.insert(peripheral)
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("Connected to peripheral: \(peripheral.identifier)")
        peripheral.discoverServices([Constants.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("Failed to connect to peripheral: \(peripheral.identifier), error: \(error?.localizedDescription ?? "none")")
        connectedPeripherals.remove(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log("Disconnected from peripheral: \(peripheral.identifier), error: \(error?.localizedDescription ?? "none")")
        connectedPeripherals.remove(peripheral)
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        log("Central will restore state: \(dict.keys.sorted())")

        // Restore connected peripherals
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                log("Restoring peripheral: \(peripheral.identifier)")
                connectedPeripherals.insert(peripheral)
                peripheral.delegate = self
            }
        }

        // Restore scanning state
        if let restoredScanServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID],
           restoredScanServices.contains(Constants.serviceUUID) {
            shouldScan = true
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            log("Error discovering services: \(error.localizedDescription)")
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }

        guard let services = peripheral.services else {
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }

        for service in services where service.uuid == Constants.serviceUUID {
            log("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics([Constants.characteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            log("Error discovering characteristics: \(error.localizedDescription)")
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }

        guard let characteristics = service.characteristics else {
            centralManager.cancelPeripheralConnection(peripheral)
            return
        }

        for char in characteristics where char.uuid == Constants.characteristicUUID {
            log("Discovered characteristic: \(char.uuid)")
            peripheral.readValue(for: char)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Always disconnect after reading
        defer {
            centralManager.cancelPeripheralConnection(peripheral)
        }

        if let error {
            log("Error reading characteristic: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value,
              let token = String(data: data, encoding: .utf8) else {
            log("Invalid characteristic data")
            return
        }

        log("Read token from peripheral: \(token)")

        // RSSI is not directly available after connection, set to 0
        let rssi: Int? = nil
        processEncounter(token: token, rssi: rssi)
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BLEManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        log("Peripheral state updated: \(peripheral.state.rawValue)")

        if peripheral.state == .poweredOn && shouldAdvertise {
            applyAdvertisingState()
        } else {
            stopAdvertisingRuntime()
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == Constants.characteristicUUID else {
            log("Read request for unknown characteristic: \(request.characteristic.uuid)")
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }

        guard let token = advertisedToken,
              let data = token.data(using: .utf8) else {
            log("No token to send")
            peripheral.respond(to: request, withResult: .unlikelyError)
            return
        }

        if request.offset > data.count {
            log("Invalid offset: \(request.offset)")
            peripheral.respond(to: request, withResult: .invalidOffset)
            return
        }

        request.value = data.subdata(in: request.offset..<data.count)
        peripheral.respond(to: request, withResult: .success)
        log("Sent token to central")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        log("Peripheral will restore state: \(dict.keys.sorted())")

        // Restore advertising state
        if let _ = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey] {
            shouldAdvertise = true
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            log("Advertising failed: \(error.localizedDescription)")
            isAdvertising = false
            return
        }
        isAdvertising = true
        log("Advertising started successfully")
    }
}

#if DEBUG
extension BLEManager {
    func _test_resetCaches() {
        resetCooldownCache()
    }
}
#endif
