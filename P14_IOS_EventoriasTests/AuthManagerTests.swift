//
//  AuthManagerTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 29/07/2026.
//

import XCTest
@testable import P14_IOS_Eventorias

@MainActor
final class AuthManagerTests: XCTestCase {

    func testSignInSuccessClearsErrorState() async {
        let mockAuthService = MockAuthService()
        let sut = AuthManager(authService: mockAuthService)

        await sut.signIn(email: "test@example.com", password: "password123")

        XCTAssertEqual(mockAuthService.signInCallCount, 1)
        XCTAssertEqual(mockAuthService.lastSignInEmail, "test@example.com")
        XCTAssertEqual(mockAuthService.lastSignInPassword, "password123")
        XCTAssertFalse(sut.isShowingSignInError)
        XCTAssertNil(sut.signInErrorMessage)
    }

    func testSignInFailureSetsErrorState() async {
        let mockAuthService = MockAuthService()
        mockAuthService.signInError = NSError(domain: "AuthTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        let sut = AuthManager(authService: mockAuthService)

        await sut.signIn(email: "test@example.com", password: "wrong-password")

        XCTAssertTrue(sut.isShowingSignInError)
        XCTAssertEqual(sut.signInErrorMessage, "Invalid credentials")
    }

    func testSignOutSuccessUpdatesAuthenticationState() {
        let mockAuthService = MockAuthService()
        let sut = AuthManager(authService: mockAuthService)

        sut.signOut()

        XCTAssertEqual(mockAuthService.signOutCallCount, 1)
        XCTAssertFalse(sut.isShowingSignOutError)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }

    func testSignOutFailureSetsErrorState() {
        let mockAuthService = MockAuthService()
        mockAuthService.signOutError = NSError(domain: "AuthTests", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sign out failed"])
        let sut = AuthManager(authService: mockAuthService)

        sut.signOut()

        XCTAssertTrue(sut.isShowingSignOutError)
        XCTAssertEqual(sut.signOutErrorMessage, "Sign out failed")
    }
}
