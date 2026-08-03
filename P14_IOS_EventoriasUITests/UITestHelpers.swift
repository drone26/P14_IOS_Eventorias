//
//  UITestHelpers.swift
//  P14_IOS_EventoriasUITests
//
//  Created by Mathieu ARRIO on 03/08/2026.
//

import XCTest

/// Shared sign-in flow for UI tests that need an authenticated session before exercising a
/// screen. Requires the Firebase Emulator Suite to be running locally
/// (`firebase emulators:start`); the app connects to it via the "UI_TESTING" launch argument
/// (see `P14_IOS_EventoriasApp.configureEmulatorsIfNeeded()`).
extension XCTestCase {
    @MainActor
    func launchAndSignIn(email: String, password: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        let emailField = app.textFields["email_field"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 10))
        emailField.tap()
        emailField.typeText(email)

        app.secureTextFields["password_field"].tap()
        app.secureTextFields["password_field"].typeText(password)

        app.buttons["authenticate_button"].tap()
        dismissPasswordSavePromptIfPresent(app)

        // SwiftUI's `Tab`-based `TabView` doesn't reliably surface a tab's `.accessibilityIdentifier`
        // to the underlying tab-bar button in XCUITest; the button's label (e.g. "Events") is always
        // exposed, so match on either identifier or label. Give it a generous window: sign-in has to
        // round-trip the emulator on a cold launch before the tab bar appears.
        let eventsTab = app.tabBars.buttons.matching(
            NSPredicate(format: "identifier == %@ OR label == %@", "events_tab", "Events")
        ).firstMatch
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 15), "Never reached the main tab bar after sign-in")
        return app
    }

    /// iOS may offer to save the just-entered credentials to the keychain after a successful
    /// sign-in; that system prompt covers the app and blocks further taps until dismissed. Its
    /// timing isn't guaranteed relative to the sign-in call — on a cold app launch it has been
    /// observed appearing several seconds later, well after this initial check's window, still
    /// blocking a later, unrelated tap (see `tapWhenHittable`, which re-checks for it too).
    /// One predicate over every locale's label avoids paying a separate timeout per language.
    @MainActor
    func dismissPasswordSavePromptIfPresent(_ app: XCUIApplication) {
        let predicate = NSPredicate(format: "label IN %@", ["Not Now", "Plus tard", "Non maintenant"])
        let button = app.buttons.matching(predicate).firstMatch
        if button.waitForExistence(timeout: 3) {
            button.tap()
        }
    }

    /// Waits until `element` exists *and* has a valid on-screen frame before tapping it.
    /// `waitForExistence` alone isn't enough: an element can appear in the accessibility tree
    /// with a real frame while still covered by the password-save prompt (see
    /// `dismissPasswordSavePromptIfPresent`), which blocks hit-testing there until dismissed —
    /// so this also re-checks for that prompt on every poll, not just once up front.
    @MainActor
    func tapWhenHittable(_ element: XCUIElement, in app: XCUIApplication, timeout: TimeInterval = 10, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "label IN %@", ["Not Now", "Plus tard", "Non maintenant"])
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            let passwordPrompt = app.buttons.matching(predicate).firstMatch
            if passwordPrompt.exists {
                passwordPrompt.tap()
            }
            if element.exists && element.isHittable {
                element.tap()
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        XCTFail("Element never became hittable", file: file, line: line)
    }
}
