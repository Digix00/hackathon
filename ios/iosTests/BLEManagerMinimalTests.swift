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

    func test_makeAdvertisingPayload_convertsHexTokenToUUID() {
        let token = "0011223344556677"

        let payload = sut._test_makeAdvertisingPayload(token: token)

        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.backendToken, token)
        XCTAssertEqual(payload?.tokenUUID.uuidString.lowercased(), uuidStringFromPrefixAndToken(prefixHex: BLEManager.Constants.tokenPrefixHex, tokenHex: token))
    }

    func test_makeAdvertisingPayload_rejectsInvalidToken() {
        XCTAssertNil(sut._test_makeAdvertisingPayload(token: "123e4567-e89b-12d3-a456-426614174000"))
        XCTAssertNil(sut._test_makeAdvertisingPayload(token: ""))
        XCTAssertNil(sut._test_makeAdvertisingPayload(token: "not-hex-token"))
        XCTAssertNil(sut._test_makeAdvertisingPayload(token: "1234"))
    }

    func test_decodeToken_requiresAppServiceUUID() {
        let token = "0011223344556677"
        guard let payload = sut._test_makeAdvertisingPayload(token: token) else {
            XCTFail("Expected payload")
            return
        }

        let missingAppService: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [payload.tokenUUID]
        ]
        XCTAssertNil(sut._test_decodeToken(fromAdvertisementData: missingAppService))
    }

    func test_decodeToken_extractsTokenUUID() {
        let token = "0011223344556677"
        guard let payload = sut._test_makeAdvertisingPayload(token: token) else {
            XCTFail("Expected payload")
            return
        }

        let data: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [BLEManager.Constants.appServiceUUID, payload.tokenUUID]
        ]

        XCTAssertEqual(sut._test_decodeToken(fromAdvertisementData: data), token)
    }

    func test_decodeToken_extractsTokenUUIDFromOverflowServiceUUIDs() {
        let token = "0011223344556677"
        guard let payload = sut._test_makeAdvertisingPayload(token: token) else {
            XCTFail("Expected payload")
            return
        }

        let data: [String: Any] = [
            CBAdvertisementDataOverflowServiceUUIDsKey: [BLEManager.Constants.appServiceUUID, payload.tokenUUID]
        ]

        XCTAssertEqual(sut._test_decodeToken(fromAdvertisementData: data), token)
    }

    func test_shouldEmitDetection_filtersByRSSI() {
        let token = "0011223344556677"
        let now = Date(timeIntervalSince1970: 0)

        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: 127), now: now))
        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -90), now: now))
    }

    func test_shouldEmitDetection_inBackgroundUsesStricterRSSIThreshold() {
        let token = "0011223344556677"
        let now = Date(timeIntervalSince1970: 0)

        sut.updateAppForegroundState(false)

        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -81), now: now))
        XCTAssertTrue(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -80), now: now))
    }

    func test_shouldEmitDetection_requiresTwoDetectionsWithinWindow() {
        let token = "0011223344556677"
        let now = Date(timeIntervalSince1970: 0)

        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now))
        XCTAssertTrue(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now.addingTimeInterval(1)))
    }

    func test_shouldEmitDetection_inBackgroundRequiresSingleDetection() {
        let token = "0011223344556677"
        let now = Date(timeIntervalSince1970: 0)

        sut.updateAppForegroundState(false)

        XCTAssertTrue(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now))
    }

    func test_shouldEmitDetection_resetsCountOutsideWindow() {
        let token = "0011223344556677"
        let now = Date(timeIntervalSince1970: 0)

        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now))
        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now.addingTimeInterval(31)))
    }

    func test_shouldEmitDetection_appliesDebounce() {
        let token = "0011223344556677"
        let now = Date(timeIntervalSince1970: 0)

        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now))
        XCTAssertTrue(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now.addingTimeInterval(1)))

        let debounceStart = now.addingTimeInterval(5)
        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: debounceStart))
        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: debounceStart.addingTimeInterval(1)))
    }

    func test_shouldEmitDetection_inBackgroundIgnoresDebounceButKeepsCooldown() {
        let token = "0011223344556677"
        let now = Date(timeIntervalSince1970: 0)

        sut.updateAppForegroundState(false)

        XCTAssertTrue(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now))
        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now.addingTimeInterval(5)))
    }

    func test_shouldEmitDetection_appliesCooldown() {
        let token = "0011223344556677"
        let now = Date(timeIntervalSince1970: 0)

        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now))
        XCTAssertTrue(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: now.addingTimeInterval(1)))

        let withinCooldown = now.addingTimeInterval(60)
        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: withinCooldown))
        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: withinCooldown.addingTimeInterval(1)))

        let afterCooldown = now.addingTimeInterval(301)
        XCTAssertFalse(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: afterCooldown))
        XCTAssertTrue(sut._test_shouldEmitDetection(token: token, rssi: NSNumber(value: -70), now: afterCooldown.addingTimeInterval(1)))
    }
}

private func uuidStringFromPrefixAndToken(prefixHex: String, tokenHex: String) -> String {
    let compact = (prefixHex + tokenHex).lowercased()
    let part1 = String(compact.prefix(8))
    let part2 = String(compact.dropFirst(8).prefix(4))
    let part3 = String(compact.dropFirst(12).prefix(4))
    let part4 = String(compact.dropFirst(16).prefix(4))
    let part5 = String(compact.dropFirst(20).prefix(12))
    return "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
}
