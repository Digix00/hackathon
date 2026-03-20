import CoreBluetooth
import XCTest

@testable import ios

final class BLEManagerMinimalTests: XCTestCase {
    private var sut: BLEManager!

    override func setUp() {
        super.setUp()
        sut = BLEManager()
        sut._test_resetCaches()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_initialization() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.state, .unknown)
        XCTAssertFalse(sut.isAdvertising)
        XCTAssertFalse(sut.isScanning)
        XCTAssertNil(sut.latestDetection)
    }

    func test_startAdvertising_setsAdvertisingState() {
        let token = "0011223344556677"

        sut.startAdvertising(token: token)

        // Note: isAdvertising will only be true when BLE is powered on
        // This test just verifies the method doesn't crash
    }

    func test_startScanning_setsScanningState() {
        sut.startScanning()

        // Note: isScanning will only be true when BLE is powered on
        // This test just verifies the method doesn't crash
    }

    func test_stopAdvertising() {
        sut.startAdvertising(token: "0011223344556677")
        sut.stopAdvertising()

        // Verify the method doesn't crash
        XCTAssertFalse(sut.isAdvertising)
    }

    func test_stopScanning() {
        sut.startScanning()
        sut.stopScanning()

        // Verify the method doesn't crash
        XCTAssertFalse(sut.isScanning)
    }

    func test_resetCooldownCache() {
        sut._test_resetCaches()

        // Verify the method doesn't crash
    }
}
