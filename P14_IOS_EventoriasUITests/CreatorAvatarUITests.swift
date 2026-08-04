//
//  CreatorAvatarUITests.swift
//  P14_IOS_EventoriasUITests
//
//  Created by Mathieu ARRIO on 04/08/2026.
//

import XCTest

/// Requires the Firebase Emulator Suite to be running locally (`firebase emulators:start`).
/// The app is launched with the "UI_TESTING" argument so it connects to the emulators instead
/// of production (see `P14_IOS_EventoriasApp.configureEmulatorsIfNeeded()`).
///
/// Exercises `CreatorAvatarView` through `EventDetailView`, where it renders standalone (unlike
/// in `EventRowView`, where `.accessibilityElement(children: .combine)` folds its label into the
/// whole row and makes its individual state unqueryable).
final class CreatorAvatarUITests: XCTestCase {
    private let testEmail = "creatoravatar-uitest@example.com"
    private let testPassword = "password123"

    override func setUp() async throws {
        continueAfterFailure = false
        try await FirebaseEmulatorTestSupport.resetState()
        try await FirebaseEmulatorTestSupport.createUser(email: testEmail, password: testPassword)
    }

    @MainActor
    private func openEventDetail(title: String, in app: XCUIApplication) {
        let row = app.buttons["event_row_\(title)"]
        tapWhenHittable(row, in: app)
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
    }

    /// The creator has no `users/{uid}` document at all, matching a real event whose creator
    /// never signed in during this test run (`avatar(for:)` decodes a nonexistent doc to nil).
    @MainActor
    func testCreatorWithNoProfileShowsPlaceholder() async throws {
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "No Creator Avatar", description: "Desc", date: .now, address: "Addr", creatorId: "nonexistent-creator"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)
        openEventDetail(title: "No Creator Avatar", in: app)

        let avatar = app.descendants(matching: .any).matching(identifier: "creator_avatar").firstMatch
        XCTAssertTrue(avatar.waitForExistence(timeout: 5))
        // Give any (unexpected) async load a moment to settle before asserting it never fires.
        try await Task.sleep(for: .seconds(1))
        XCTAssertEqual(avatar.label, "Creator avatar placeholder")
    }

    /// A creator with a resolvable `avatarUrl` should have their photo fetched and cached. The
    /// list row loads the same creatorId first; visiting the detail screen afterwards should hit
    /// `LocalImageCache` instead of re-fetching, exercising that branch too.
    @MainActor
    func testCreatorWithAvatarUrlLoadsPhotoAndDetailReusesCache() async throws {
        let avatarUrl = try await FirebaseEmulatorTestSupport.uploadTestImage(path: "test-avatars/creator-1.png")
        try await FirebaseEmulatorTestSupport.setUserAvatarUrl(uid: "avatar-creator", avatarUrl: avatarUrl)
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Avatar Creator Event", description: "Desc", date: .now, address: "Addr", creatorId: "avatar-creator"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)

        let row = app.buttons["event_row_Avatar Creator Event"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let rowAvatarLoaded = NSPredicate(format: "label CONTAINS 'Creator avatar photo'")
        await fulfillment(of: [expectation(for: rowAvatarLoaded, evaluatedWith: row)], timeout: 8)

        openEventDetail(title: "Avatar Creator Event", in: app)

        let detailAvatar = app.descendants(matching: .any).matching(identifier: "creator_avatar").firstMatch
        XCTAssertTrue(detailAvatar.waitForExistence(timeout: 5))
        // Already cached by the row's load above, so this should resolve near-instantly.
        let detailAvatarLoaded = NSPredicate(format: "label == 'Creator avatar photo'")
        await fulfillment(of: [expectation(for: detailAvatarLoaded, evaluatedWith: detailAvatar)], timeout: 3)
    }

    /// An `avatarUrl` pointing at an unreachable host fails the fetch silently by design
    /// (`loadAvatar` just returns), so the view should stay on the loading placeholder forever
    /// rather than crash or show a broken image.
    @MainActor
    func testCreatorWithUnreachableAvatarUrlStaysOnLoadingPlaceholder() async throws {
        try await FirebaseEmulatorTestSupport.setUserAvatarUrl(uid: "broken-avatar-creator", avatarUrl: "http://127.0.0.1:9/does-not-exist.jpg")
        try await FirebaseEmulatorTestSupport.createEvent(
            title: "Broken Avatar Event", description: "Desc", date: .now, address: "Addr", creatorId: "broken-avatar-creator"
        )

        let app = launchAndSignIn(email: testEmail, password: testPassword)
        openEventDetail(title: "Broken Avatar Event", in: app)

        let avatar = app.descendants(matching: .any).matching(identifier: "creator_avatar").firstMatch
        XCTAssertTrue(avatar.waitForExistence(timeout: 5))
        let loadingAppeared = NSPredicate(format: "label == 'Creator avatar loading'")
        await fulfillment(of: [expectation(for: loadingAppeared, evaluatedWith: avatar)], timeout: 8)

        // Confirm it never progresses past the loading state once the fetch has had time to fail.
        try await Task.sleep(for: .seconds(2))
        XCTAssertEqual(avatar.label, "Creator avatar loading")
    }
}
