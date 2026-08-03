//
//  ProfileUITests.swift
//  P14_IOS_EventoriasUITests
//
//  Created by Mathieu ARRIO on 03/08/2026.
//

import XCTest

/// Requires the Firebase Emulator Suite to be running locally (`firebase emulators:start`).
/// The app is launched with the "UI_TESTING" argument so it connects to the emulators instead
/// of production (see `P14_IOS_EventoriasApp.configureEmulatorsIfNeeded()`).
final class ProfileUITests: XCTestCase {
    private let testEmail = "profile-uitest@example.com"
    private let testPassword = "password123"

    private var testUid = ""

    override func setUp() async throws {
        continueAfterFailure = false
        try await FirebaseEmulatorTestSupport.resetState()
        testUid = try await FirebaseEmulatorTestSupport.createUser(email: testEmail, password: testPassword)
    }

    /// Switches to the Profile tab and waits for its content to finish loading (it shows a
    /// spinner in place of everything, including `sign_out_button`, while `isLoading` is true).
    @MainActor
    private func openProfileTab(_ app: XCUIApplication) {
        let profileTab = app.tabBars.buttons["profile_tab"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()
        XCTAssertTrue(app.staticTexts["profile_email_text"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testProfileDisplaysSignedInUserEmail() throws {
        let app = launchAndSignIn(email: testEmail, password: testPassword)

        openProfileTab(app)

        let emailText = app.staticTexts["profile_email_text"]
        XCTAssertEqual(emailText.label, testEmail)
    }

    @MainActor
    func testToggleNotificationsPersistsAcrossRelaunch() async throws {
        let app = launchAndSignIn(email: testEmail, password: testPassword)
        openProfileTab(app)

        let toggle = app.descendants(matching: .any)["profile_notifications_toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "0")

        // The switch's visual control sits at the row's trailing edge; tapping the accessibility
        // frame's center (the default for `.tap()`) can land over the "Notifications" label
        // instead, outside a List/Form row context.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let toggledOn = expectation(for: NSPredicate(format: "value == '1'"), evaluatedWith: toggle)
        await fulfillment(of: [toggledOn], timeout: 5)

        // `ProfileViewModel.setNotificationsEnabled` flips the toggle optimistically before its
        // Firestore write resolves, so the UI turning "1" doesn't guarantee the write landed.
        // `app.terminate()` SIGKILLs the process, which would lose an in-flight write outright
        // (the emulator config uses an in-memory Firestore cache, so nothing queues it for
        // replay) — confirm the server actually has it first.
        let persisted = try await FirebaseEmulatorTestSupport.waitForNotificationsEnabled(uid: testUid, expected: true)
        XCTAssertTrue(persisted, "Firestore write never landed before relaunch")

        app.terminate()
        let relaunched = launchAndSignIn(email: testEmail, password: testPassword)
        openProfileTab(relaunched)

        let reloadedToggle = relaunched.descendants(matching: .any)["profile_notifications_toggle"]
        XCTAssertTrue(reloadedToggle.waitForExistence(timeout: 5))
        XCTAssertEqual(reloadedToggle.value as? String, "1")
    }

    @MainActor
    func testSignOutReturnsToSignInScreen() throws {
        let app = launchAndSignIn(email: testEmail, password: testPassword)

        openProfileTab(app)
        let signOutButton = app.buttons["sign_out_button"]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5))
        signOutButton.tap()

        XCTAssertTrue(app.textFields["email_field"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.buttons["profile_tab"].exists)
    }
}
