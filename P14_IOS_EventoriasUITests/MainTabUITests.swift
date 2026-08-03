//
//  MainTabUITests.swift
//  P14_IOS_EventoriasUITests
//
//  Created by Mathieu ARRIO on 03/08/2026.
//

import XCTest

/// Requires the Firebase Emulator Suite to be running locally (`firebase emulators:start`).
/// The app is launched with the "UI_TESTING" argument so it connects to the emulators instead
/// of production (see `P14_IOS_EventoriasApp.configureEmulatorsIfNeeded()`).
final class MainTabUITests: XCTestCase {
    private let testEmail = "maintab-uitest@example.com"
    private let testPassword = "password123"

    override func setUp() async throws {
        continueAfterFailure = false
        try await FirebaseEmulatorTestSupport.resetState()
        try await FirebaseEmulatorTestSupport.createUser(email: testEmail, password: testPassword)
    }

    @MainActor
    func testSwitchingBetweenTabsShowsExpectedContent() throws {
        let app = launchAndSignIn(email: testEmail, password: testPassword)

        XCTAssertTrue(app.tabBars.buttons["events_tab"].exists)
        XCTAssertTrue(app.tabBars.buttons["profile_tab"].exists)
        // Events is the first tab, so it should already be selected right after sign-in.
        XCTAssertTrue(app.buttons["create_event_button"].waitForExistence(timeout: 5))

        app.tabBars.buttons["profile_tab"].tap()
        XCTAssertTrue(app.staticTexts["profile_email_text"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["create_event_button"].exists)

        app.tabBars.buttons["events_tab"].tap()
        XCTAssertTrue(app.buttons["create_event_button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["profile_email_text"].exists)
    }
}
