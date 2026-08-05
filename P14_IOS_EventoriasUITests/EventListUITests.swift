//
//  EventListUITests.swift
//  P14_IOS_EventoriasUITests
//
//  Created by Mathieu ARRIO on 03/08/2026.
//

import XCTest

/// Requires the Firebase Emulator Suite to be running locally (`firebase emulators:start`).
/// The app is launched with the "UI_TESTING" argument so it connects to the emulators instead
/// of production (see `P14_IOS_EventoriasApp.configureEmulatorsIfNeeded()`).
final class EventListUITests: XCTestCase {
    private let testEmail = "eventlist-uitest@example.com"
    private let testPassword = "password123"

    override func setUp() async throws {
        continueAfterFailure = false
        try await FirebaseEmulatorTestSupport.resetState()
        try await FirebaseEmulatorTestSupport.createUser(email: testEmail, password: testPassword)
    }

    @MainActor
    func testEmptyEventListShowsPlaceholder() throws {
        let app = launchAndSignIn(email: testEmail, password: testPassword)

        XCTAssertTrue(app.staticTexts["No event found."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEventListDisplaysSeededEvent() async throws {
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Music Festival",
            description: "Live music all night",
            date: .now,
            address: "1 Infinite Loop, Cupertino, CA",
            creatorId: "some-other-user"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)

        XCTAssertTrue(app.buttons["event_row_Music Festival"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSearchFiltersEventsByTitle() async throws {
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Alpha Concert", description: "Desc", date: .now, address: "Addr", creatorId: "creator"
        )
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Beta Meetup", description: "Desc", date: .now, address: "Addr", creatorId: "creator"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)
        XCTAssertTrue(app.buttons["event_row_Alpha Concert"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["event_row_Beta Meetup"].exists)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Alpha")

        XCTAssertTrue(app.buttons["event_row_Alpha Concert"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["event_row_Beta Meetup"].exists)
    }

    @MainActor
    func testSortMenuReordersEventsByTitle() async throws {
        // Chosen so date order and alphabetical order disagree, proving the sort actually ran.
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Zebra Show", description: "Desc", date: .now, address: "Addr", creatorId: "creator"
        )
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Apple Fair", description: "Desc", date: .now.addingTimeInterval(3600), address: "Addr", creatorId: "creator"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)
        XCTAssertTrue(app.buttons["event_row_Zebra Show"].waitForExistence(timeout: 5))

        func rowIdentifiers() -> [String] {
            let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'event_row_'"))
            return (0..<rows.count).map { rows.element(boundBy: $0).identifier }
        }

        // Default sort is ascending by date: "Zebra Show" (earlier) before "Apple Fair" (later).
        XCTAssertEqual(rowIdentifiers(), ["event_row_Zebra Show", "event_row_Apple Fair"])

        app.buttons["sort_menu"].tap()
        let titleSortOption = app.buttons["Title (A-Z)"]
        XCTAssertTrue(titleSortOption.waitForExistence(timeout: 5))
        titleSortOption.tap()

        XCTAssertEqual(rowIdentifiers(), ["event_row_Apple Fair", "event_row_Zebra Show"])
    }

    @MainActor
    func testSortMenuDateDescendingOrdersEventsByDate() async throws {
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Early Show", description: "Desc", date: .now, address: "Addr", creatorId: "creator"
        )
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Late Show", description: "Desc", date: .now.addingTimeInterval(3600), address: "Addr", creatorId: "creator"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)
        XCTAssertTrue(app.buttons["event_row_Early Show"].waitForExistence(timeout: 5))

        func rowIdentifiers() -> [String] {
            let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'event_row_'"))
            return (0..<rows.count).map { rows.element(boundBy: $0).identifier }
        }

        XCTAssertEqual(rowIdentifiers(), ["event_row_Early Show", "event_row_Late Show"])

        app.buttons["sort_menu"].tap()
        let dateDescOption = app.buttons["Date (Farthest)"]
        XCTAssertTrue(dateDescOption.waitForExistence(timeout: 5))
        dateDescOption.tap()

        XCTAssertEqual(rowIdentifiers(), ["event_row_Late Show", "event_row_Early Show"])
    }

    @MainActor
    func testSearchWithNoMatchesShowsEmptyState() async throws {
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Alpha Concert", description: "Desc", date: .now, address: "Addr", creatorId: "creator"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)
        XCTAssertTrue(app.buttons["event_row_Alpha Concert"].waitForExistence(timeout: 5))

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("NoSuchEventTitle")

        XCTAssertTrue(app.staticTexts["No event found."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["event_row_Alpha Concert"].exists)
    }

    @MainActor
    func testPullToRefreshReloadsEvents() async throws {
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Refresh Test Event", description: "Desc", date: .now, address: "Addr", creatorId: "creator"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)
        XCTAssertTrue(app.buttons["event_row_Refresh Test Event"].waitForExistence(timeout: 5))

        let scrollView = app.scrollViews.firstMatch
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05))
        let finish = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.05, thenDragTo: finish)

        XCTAssertTrue(app.buttons["event_row_Refresh Test Event"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCreateEventButtonNavigatesToCreationScreen() throws {
        let app = launchAndSignIn(email: testEmail, password: testPassword)

        tapWhenHittable(app.buttons["create_event_button"], in: app)

        XCTAssertTrue(app.textFields["event_title_field"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEventRowWithoutCoverImageShowsPlaceholder() async throws {
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "No Cover Event", description: "Desc", date: .now, address: "Addr", creatorId: "creator"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)

        let row = app.buttons["event_row_No Cover Event"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("No cover photo"))
    }

    @MainActor
    func testEventRowWithBrokenCoverImageUrlShowsFailureState() async throws {
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Broken Cover Event", description: "Desc", date: .now, address: "Addr", creatorId: "creator",
            coverImageUrl: "http://127.0.0.1:9/does-not-exist.jpg"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)

        let row = app.buttons["event_row_Broken Cover Event"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        // AsyncImage settles asynchronously, so poll until the failure label lands.
        let failureLabelAppeared = NSPredicate(format: "label CONTAINS 'Cover photo unavailable'")
        await fulfillment(of: [expectation(for: failureLabelAppeared, evaluatedWith: row)], timeout: 5)
    }
}
