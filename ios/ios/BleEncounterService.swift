import CoreBluetooth
import Combine
import Foundation

protocol BleTokenProviding {
    func currentBleToken() -> String?
}

struct EmptyBleTokenProvider: BleTokenProviding {
    func currentBleToken() -> String? { nil }
}

@MainActor
final class BleEncounterService: NSObject, ObservableObject {
    struct Constants {
        static let serviceUUID = CBUUID(string: "00001234-0000-1000-8000-00805F9B34FB")
        static let scanInterval: Duration = .seconds(5)
        static let scanWindow: Duration = .seconds(2)
        static let cooldown: TimeInterval = 300
        static let minRSSI = -90
        static let minTokenBytes = 8
        static let maxTokenBytes = 16
    }

    @Published private(set) var isRunning = false

    private let tokenProvider: BleTokenProviding
    private let centralManager: CBCentralManager
    private let peripheralManager: CBPeripheralManager

    private var scanTask: Task<Void, Never>?
    private var isScanning = false
    private var currentToken: String?
    private var lastDetectionAtByToken: [String: Date] = [:]

    var onTokenDetected: ((String, Int) -> Void)?

    init(tokenProvider: BleTokenProviding, onTokenDetected: ((String, Int) -> Void)? = nil) {
        self.tokenProvider = tokenProvider
        self.onTokenDetected = onTokenDetected
        self.centralManager = CBCentralManager(delegate: nil, queue: .main)
        self.peripheralManager = CBPeripheralManager(delegate: nil, queue: .main)
        super.init()
        self.centralManager.delegate = self
        self.peripheralManager.delegate = self
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        refreshAdvertisingToken()
        reconfigureBleWork()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        stopScheduledScan()
        stopAdvertising()
    }

    func refreshAdvertisingToken() {
        guard let token = tokenProvider.currentBleToken(), tokenByteCountIsValid(token) else {
            currentToken = nil
            stopAdvertising()
            return
        }
        let shouldRestart = currentToken != token
        currentToken = token
        if shouldRestart {
            restartAdvertisingIfPossible()
        }
    }

    private func reconfigureBleWork() {
        guard isRunning else {
            stopScheduledScan()
            stopAdvertising()
            return
        }

        if centralManager.state == .poweredOn {
            startScheduledScan()
        }
        if peripheralManager.state == .poweredOn {
            restartAdvertisingIfPossible()
        }
    }

    private func tokenByteCountIsValid(_ token: String) -> Bool {
        let byteCount = token.lengthOfBytes(using: .utf8)
        return (Constants.minTokenBytes...Constants.maxTokenBytes).contains(byteCount)
    }

    private func startScheduledScan() {
        guard scanTask == nil else { return }
        scanTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled && self.isRunning {
                self.startScanWindow()
                try? await Task.sleep(for: Constants.scanWindow)
                self.stopScanWindow()
                let idle = Constants.scanInterval - Constants.scanWindow
                if idle > .zero {
                    try? await Task.sleep(for: idle)
                }
            }
        }
    }

    private func stopScheduledScan() {
        scanTask?.cancel()
        scanTask = nil
        stopScanWindow()
    }

    private func startScanWindow() {
        guard !isScanning, centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(
            withServices: [Constants.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
    }

    private func stopScanWindow() {
        guard isScanning else { return }
        centralManager.stopScan()
        isScanning = false
    }

    private func restartAdvertisingIfPossible() {
        stopAdvertising()
        guard isRunning, peripheralManager.state == .poweredOn else { return }
        guard let token = currentToken, let tokenData = token.data(using: .utf8) else { return }

        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [Constants.serviceUUID],
            CBAdvertisementDataServiceDataKey: [Constants.serviceUUID: tokenData]
        ]
        peripheralManager.startAdvertising(advertisementData)
    }

    private func stopAdvertising() {
        if peripheralManager.isAdvertising {
            peripheralManager.stopAdvertising()
        }
    }

    private func handleDetectedToken(_ token: String, rssi: Int, at detectedAt: Date) {
        guard rssi >= Constants.minRSSI else { return }
        guard tokenByteCountIsValid(token) else { return }

        if let lastDetection = lastDetectionAtByToken[token], detectedAt.timeIntervalSince(lastDetection) < Constants.cooldown {
            return
        }
        lastDetectionAtByToken[token] = detectedAt
        trimCooldownCache(olderThan: detectedAt.addingTimeInterval(-Constants.cooldown))
        onTokenDetected?(token, rssi)
    }

    private func trimCooldownCache(olderThan threshold: Date) {
        lastDetectionAtByToken = lastDetectionAtByToken.filter { $0.value >= threshold }
    }
}

extension BleEncounterService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state != .poweredOn {
            stopScheduledScan()
            return
        }
        if isRunning {
            startScheduledScan()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let now = Date()
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
           let raw = serviceData[Constants.serviceUUID],
           let token = String(data: raw, encoding: .utf8) {
            handleDetectedToken(token, rssi: RSSI.intValue, at: now)
            return
        }

        if let manufacturer = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
           let token = String(data: manufacturer, encoding: .utf8) {
            handleDetectedToken(token, rssi: RSSI.intValue, at: now)
        }
    }
}

extension BleEncounterService: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state != .poweredOn {
            stopAdvertising()
            return
        }
        if isRunning {
            restartAdvertisingIfPossible()
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if error != nil {
            stopAdvertising()
        }
    }
}
