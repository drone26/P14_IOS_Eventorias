//
//  EventCreationUITests.swift
//  P14_IOS_EventoriasUITests
//
//  Created by Mathieu ARRIO on 03/08/2026.
//

import XCTest

/// Requires the Firebase Emulator Suite to be running locally (`firebase emulators:start`).
/// The app is launched with the "UI_TESTING" argument so it connects to the emulators instead
/// of production (see `P14_IOS_EventoriasApp.configureEmulatorsIfNeeded()`).
final class EventCreationUITests: XCTestCase {
    private let testEmail = "eventcreation-uitest@example.com"
    private let testPassword = "password123"

    override func setUp() async throws {
        continueAfterFailure = false
        try await FirebaseEmulatorTestSupport.resetState()
        try await FirebaseEmulatorTestSupport.createUser(email: testEmail, password: testPassword)
    }

    @MainActor
    private func openCreationScreen() -> XCUIApplication {
        let app = launchAndSignIn(email: testEmail, password: testPassword)
        tapWhenHittable(app.buttons["create_event_button"], in: app)
        XCTAssertTrue(app.textFields["event_title_field"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    func testSaveWithEmptyFieldsShowsValidationError() throws {
        let app = openCreationScreen()

        app.buttons["save_event_button"].tap()

        let errorText = app.staticTexts["error_message_text"]
        XCTAssertTrue(errorText.waitForExistence(timeout: 5))
        XCTAssertEqual(errorText.label, "Please fill in all fields.")
    }

    @MainActor
    func testCreatingEventNavigatesBackAndAppearsInList() throws {
        let app = openCreationScreen()

        app.textFields["event_title_field"].tap()
        app.textFields["event_title_field"].typeText("Jazz Night")

        app.textFields["event_description_field"].tap()
        app.textFields["event_description_field"].typeText("An evening of live jazz")

        app.textFields["event_address_field"].tap()
        app.textFields["event_address_field"].typeText("42 Rue de la Musique, Paris")

        app.buttons["save_event_button"].tap()

        // Saving dismisses back to the event list.
        XCTAssertTrue(app.buttons["create_event_button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["event_row_Jazz Night"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCameraButtonIsDisabledOnSimulator() throws {
        let app = openCreationScreen()

        let cameraButton = app.buttons["camera_button"]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5))
        // The Simulator has no camera hardware, so `UIImagePickerController.isSourceTypeAvailable(.camera)` is false.
        XCTAssertFalse(cameraButton.isEnabled)
    }

    @MainActor
    func testPhotoLibraryButtonIsAvailable() throws {
        let app = openCreationScreen()

        let photoLibraryButton = app.buttons["photo_library_button"]
        XCTAssertTrue(photoLibraryButton.waitForExistence(timeout: 5))
        XCTAssertTrue(photoLibraryButton.isEnabled)
    }
}
