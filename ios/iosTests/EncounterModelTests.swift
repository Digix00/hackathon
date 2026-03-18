import SwiftUI
import XCTest

@testable import ios

final class EncounterModelTests: XCTestCase {
    private func makeEncounter(relativeTime: String) -> Encounter {
        Encounter(
            id: "enc-1",
            userName: "mio",
            track: Track(title: "Song", artist: "Artist", color: .blue),
            relativeTime: relativeTime,
            lyric: ""
        )
    }

    func testEncounterHappenedTodayMatchesRelativeTimeLabels() {
        let samples = ["たった今", "3分前", "2時間前", "近日"]

        for label in samples {
            let encounter = makeEncounter(relativeTime: label)
            XCTAssertTrue(encounter.happenedToday, "Expected \(label) to be treated as today")
            XCTAssertFalse(encounter.happenedYesterday)
            XCTAssertFalse(encounter.happenedEarlier)
        }
    }

    func testEncounterHappenedYesterdayMatchesLabel() {
        let encounter = makeEncounter(relativeTime: "昨日")

        XCTAssertTrue(encounter.happenedYesterday)
        XCTAssertFalse(encounter.happenedToday)
        XCTAssertFalse(encounter.happenedEarlier)
    }

    func testEncounterHappenedEarlierForPastDays() {
        let encounter = makeEncounter(relativeTime: "2日前")

        XCTAssertTrue(encounter.happenedEarlier)
        XCTAssertFalse(encounter.happenedToday)
        XCTAssertFalse(encounter.happenedYesterday)
    }

    func testEncounterSectionsIncludeExpectedEncounters() {
        let today = makeEncounter(relativeTime: "5分前")
        let yesterday = makeEncounter(relativeTime: "昨日")
        let earlier = makeEncounter(relativeTime: "3日前")

        XCTAssertTrue(EncounterSection.today.includes(today))
        XCTAssertTrue(EncounterSection.yesterday.includes(yesterday))
        XCTAssertTrue(EncounterSection.earlier.includes(earlier))

        XCTAssertFalse(EncounterSection.today.includes(earlier))
        XCTAssertFalse(EncounterSection.yesterday.includes(today))
    }
}
