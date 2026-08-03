//
//  SignInUITests.swift
//  P14_IOS_EventoriasUITests
//
//  Created by Mathieu ARRIO on 03/08/2026.
//

import XCTest

/// Requires the Firebase Emulator Suite to be running locally (`firebase emulators:start`).
/// The app is launched with the "UI_TESTING" argument so it connects to the emulators instead
/// of production (see `P14_IOS_EventoriasApp.configureEmulatorsIfNeeded()`).
final class SignInUITests: XCTestCase {
    private let testEmail = "signin-uitest@example.com"
    private let testPassword = "password123"

    override func setUp() async throws {
        continueAfterFailure = false
        try await FirebaseEmulatorTestSupport.resetState()
    }

    @MainActor
    func testSignInWithValidCredentialsShowsEventsList() async throws {
        try await FirebaseEmulatorTestSupport.createUser(email: testEmail, password: testPassword)

        _ = launchAndSignIn(email: testEmail, password: testPassword)
    }

    @MainActor
    func testSignInWithUnknownCredentialsShowsError() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        app.textFields["email_field"].tap()
        app.textFields["email_field"].typeText("unknown@example.com")

        app.secureTextFields["password_field"].tap()
        app.secureTextFields["password_field"].typeText("wrong-password")

        app.buttons["authenticate_button"].tap()

        XCTAssertTrue(app.staticTexts["error_message_text"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.buttons["events_tab"].exists)
    }

    @MainActor
    func testAuthenticateButtonIsDisabledUntilFormIsComplete() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        let authenticateButton = app.buttons["authenticate_button"]
        XCTAssertTrue(authenticateButton.waitForExistence(timeout: 5))
        XCTAssertFalse(authenticateButton.isEnabled)

        app.textFields["email_field"].tap()
        app.textFields["email_field"].typeText(testEmail)
        XCTAssertFalse(authenticateButton.isEnabled)

        app.secureTextFields["password_field"].tap()
        app.secureTextFields["password_field"].typeText(testPassword)
        XCTAssertTrue(authenticateButton.isEnabled)
    }
}
