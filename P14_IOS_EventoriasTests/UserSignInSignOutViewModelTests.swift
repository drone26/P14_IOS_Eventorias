//
//  UserSignInSignOutViewModelTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 29/07/2026.
//

import XCTest
@testable import P14_IOS_Eventorias

@MainActor
final class UserSignInSignOutViewModelTests: XCTestCase {

    func testCanSubmitIsFalseWhenEmailOrPasswordIsEmpty() {
        let sut = UserSignInSignOutViewModel(authManager: AuthManager(authService: MockAuthService()))

        XCTAssertFalse(sut.canSubmit)

        sut.email = "test@example.com"
        XCTAssertFalse(sut.canSubmit)

        sut.password = "password123"
        XCTAssertTrue(sut.canSubmit)
    }

    func testSignInDoesNothingWhenFormIsIncomplete() async {
        let mockAuthService = MockAuthService()
        let sut = UserSignInSignOutViewModel(authManager: AuthManager(authService: mockAuthService))
        sut.email = "test@example.com"

        await sut.signIn()

        XCTAssertEqual(mockAuthService.signInCallCount, 0)
        XCTAssertFalse(sut.isSigningIn)
    }

    func testSignInSuccessCallsAuthManagerAndClearsErrorState() async {
        let mockAuthService = MockAuthService()
        let sut = UserSignInSignOutViewModel(authManager: AuthManager(authService: mockAuthService))
        sut.email = "test@example.com"
        sut.password = "password123"

        await sut.signIn()

        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertEqual(mockAuthService.lastSignInEmail, "test@example.com")
        XCTAssertEqual(mockAuthService.lastSignInPassword, "password123")
        XCTAssertFalse(sut.isSigningIn)
        XCTAssertFalse(sut.isShowingSignInError)
        XCTAssertNil(sut.signInErrorMessage)
    }

    func testSignInFailureSetsErrorState() async {
        let mockAuthService = MockAuthService()
        mockAuthService.signInError = NSError(domain: "AuthTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        let sut = UserSignInSignOutViewModel(authManager: AuthManager(authService: mockAuthService))
        sut.email = "test@example.com"
        sut.password = "wrong-password"

        await sut.signIn()

        XCTAssertFalse(sut.isSigningIn)
        XCTAssertTrue(sut.isShowingSignInError)
        XCTAssertEqual(sut.signInErrorMessage, "Invalid credentials")
    }

    func testSignOutSuccessUpdatesAuthenticationState() {
        let mockAuthService = MockAuthService()
        let sut = UserSignInSignOutViewModel(authManager: AuthManager(authService: mockAuthService))

        sut.signOut()

        XCTAssertEqual(mockAuthService.signOutCallCount, 1)
        XCTAssertFalse(sut.isShowingSignOutError)
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testSignOutFailureSetsErrorState() {
        let mockAuthService = MockAuthService()
        mockAuthService.signOutError = NSError(domain: "AuthTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sign out failed"])
        let sut = UserSignInSignOutViewModel(authManager: AuthManager(authService: mockAuthService))

        sut.signOut()

        XCTAssertTrue(sut.isShowingSignOutError)
        XCTAssertEqual(sut.signOutErrorMessage, "Sign out failed")
    }

    func testIsAuthenticatedReflectsAuthManagerState() {
        let authManager = AuthManager(authService: MockAuthService())
        let sut = UserSignInSignOutViewModel(authManager: authManager)

        XCTAssertFalse(sut.isAuthenticated)

        authManager.isAuthenticated = true

        XCTAssertTrue(sut.isAuthenticated)
    }

    func testIsShowingSignInErrorSetterUpdatesAuthManager() async {
        let mockAuthService = MockAuthService()
        mockAuthService.signInError = NSError(domain: "AuthTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        let sut = UserSignInSignOutViewModel(authManager: AuthManager(authService: mockAuthService))
        sut.email = "test@example.com"
        sut.password = "wrong-password"
        await sut.signIn()

        XCTAssertTrue(sut.isShowingSignInError)

        sut.isShowingSignInError = false

        XCTAssertFalse(sut.isShowingSignInError)
    }

    func testIsShowingSignOutErrorSetterUpdatesAuthManager() {
        let mockAuthService = MockAuthService()
        mockAuthService.signOutError = NSError(domain: "AuthTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sign out failed"])
        let sut = UserSignInSignOutViewModel(authManager: AuthManager(authService: mockAuthService))
        sut.signOut()

        XCTAssertTrue(sut.isShowingSignOutError)

        sut.isShowingSignOutError = false

        XCTAssertFalse(sut.isShowingSignOutError)
    }

    func testDefaultInitializerUsesSharedAuthManager() {
        let sut = UserSignInSignOutViewModel()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertFalse(sut.canSubmit)
    }
}
