//
//  FirebaseAuthManager.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 15/06/2026.
//

import Foundation
import FirebaseAuth
import Observation

protocol AuthServiceProtocol {
    var currentUser: FirebaseAuth.User? { get }

    func signIn(withEmail email: String, password: String) async throws
    func signOut() throws
    @discardableResult
    func addStateDidChangeListener(_ listener: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle
}

extension Auth: AuthServiceProtocol {
    func signIn(withEmail email: String, password: String) async throws {
        let _: AuthDataResult = try await self.signIn(withEmail: email, password: password)
    }

    func addStateDidChangeListener(_ listener: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        addStateDidChangeListener { _, user in
            listener(user)
        }
    }
}

@Observable
class AuthManager {
    var isAuthenticated: Bool = false
    var currentUser: FirebaseAuth.User?
    var isShowingSignInError = false
    var signInErrorMessage: String?
    var isShowingSignOutError = false
    var signOutErrorMessage: String?

    private let authService: AuthServiceProtocol
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    init(authService: AuthServiceProtocol = Auth.auth()) {
        self.authService = authService
        self.authStateListenerHandle = self.authService.addStateDidChangeListener { [weak self] user in
            self?.currentUser = user
            self?.isAuthenticated = user != nil
        }
    }

    func signIn(email: String, password: String) async {
        do {
            try await authService.signIn(withEmail: email, password: password)
        } catch {
            signInErrorMessage = error.localizedDescription
            isShowingSignInError = true
        }
    }

    func signOut() {
        do {
            try authService.signOut()
        } catch {
            signOutErrorMessage = error.localizedDescription
            isShowingSignOutError = true
        }
    }
}
