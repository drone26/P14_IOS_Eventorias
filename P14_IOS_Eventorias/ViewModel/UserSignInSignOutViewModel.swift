//
//  UserSignInSignOutViewModel.swift
//  P14_DA-iOS_Eventorias
//
//  Created by Mathieu ARRIO on 29/07/2026.
//

import Foundation
import Observation

@Observable
final class UserSignInSignOutViewModel {
    var email = ""
    var password = ""
    var isSigningIn = false

    private let authManager: AuthManager

    init(authManager: AuthManager = AuthManager()) {
        self.authManager = authManager
    }

    var isAuthenticated: Bool {
        authManager.isAuthenticated
    }

    var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var isShowingSignInError: Bool {
        get { authManager.isShowingSignInError }
        set { authManager.isShowingSignInError = newValue }
    }

    var signInErrorMessage: String? {
        authManager.signInErrorMessage
    }

    var isShowingSignOutError: Bool {
        get { authManager.isShowingSignOutError }
        set { authManager.isShowingSignOutError = newValue }
    }

    var signOutErrorMessage: String? {
        authManager.signOutErrorMessage
    }

    func signIn() async {
        guard canSubmit else { return }

        isSigningIn = true
        await authManager.signIn(email: email, password: password)
        isSigningIn = false
    }

    func signOut() {
        authManager.signOut()
    }
}
