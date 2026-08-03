//
//  EventDetailUITests.swift
//  P14_IOS_EventoriasUITests
//
//  Created by Mathieu ARRIO on 03/08/2026.
//

import XCTest

/// Requires the Firebase Emulator Suite to be running locally (`firebase emulators:start`).
/// The app is launched with the "UI_TESTING" argument so it connects to the emulators instead
/// of production (see `P14_IOS_EventoriasApp.configureEmulatorsIfNeeded()`).
final class EventDetailUITests: XCTestCase {
    private let testEmail = "eventdetail-uitest@example.com"
    private let testPassword = "password123"

    override func setUp() async throws {
        continueAfterFailure = false
        try await FirebaseEmulatorTestSupport.resetState()
        try await FirebaseEmulatorTestSupport.createUser(email: testEmail, password: testPassword)
    }

    @MainActor
    private func seedAndOpenComedyNightDetail() async throws -> XCUIApplication {
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Comedy Night",
            description: "An evening of stand-up comedy with local artists.",
            date: .now,
            address: "10 Rue du Rire, Lyon",
            creatorId: "some-other-user"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)
        let row = app.buttons["event_row_Comedy Night"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        XCTAssertTrue(app.navigationBars["Comedy Night"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    func testTappingEventRowShowsItsDetails() async throws {
        let app = try await seedAndOpenComedyNightDetail()

        let descriptionText = app.staticTexts["event_detail_description"]
        XCTAssertTrue(descriptionText.waitForExistence(timeout: 5))
        XCTAssertEqual(descriptionText.label, "An evening of stand-up comedy with local artists.")

        let addressText = app.staticTexts["event_detail_address"]
        XCTAssertTrue(addressText.exists)
        XCTAssertEqual(addressText.label, "10 Rue du Rire, Lyon")
    }

    @MainActor
    func testBackButtonReturnsToEventList() async throws {
        let app = try await seedAndOpenComedyNightDetail()

        app.navigationBars["Comedy Night"].buttons.firstMatch.tap()

        XCTAssertTrue(app.buttons["create_event_button"].waitForExistence(timeout: 5))
    }
}
