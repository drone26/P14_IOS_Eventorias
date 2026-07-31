//
//  MockAuthService.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 29/07/2026.
//

import Foundation
import FirebaseAuth
@testable import P14_IOS_Eventorias

@MainActor
final class MockAuthService: AuthServiceProtocol {
    var currentUser: FirebaseAuth.User?

    var signInError: Error?
    var signOutError: Error?

    private(set) var signInCallCount = 0
    private(set) var signOutCallCount = 0
    private(set) var lastSignInEmail: String?
    private(set) var lastSignInPassword: String?

    private var stateDidChangeListener: ((FirebaseAuth.User?) -> Void)?

    func signIn(withEmail email: String, password: String) async throws {
        signInCallCount += 1
        lastSignInEmail = email
        lastSignInPassword = password

        if let signInError {
            throw signInError
        }
    }

    func signOut() throws {
        signOutCallCount += 1

        if let signOutError {
            throw signOutError
        }

        currentUser = nil
        notifyStateDidChange()
    }

    func addStateDidChangeListener(_ listener: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        stateDidChangeListener = listener
        return NSObject()
    }

    private func notifyStateDidChange() {
        stateDidChangeListener?(currentUser)
    }
}
