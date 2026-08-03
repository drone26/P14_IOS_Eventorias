//
//  ProfileViewModel.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    var profile: UserProfile?
    var isLoading = false
    var errorMessage: String?

    private let userRepository: UserRepositoryProtocol

    init(userRepository: UserRepositoryProtocol? = nil) {
        self.userRepository = userRepository ?? FirebaseUserRepository()
    }

    /// Loads the signed-in user's profile, creating a default document from their Firebase Auth
    /// identity the first time they open the screen.
    func loadProfile(uid: String?, displayName: String?, email: String?) async {
        guard let uid else {
            errorMessage = "User not logged in."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if let existingProfile = try await userRepository.fetchProfile(uid: uid, forceRefresh: false) {
                profile = existingProfile
            } else {
                let defaultProfile = UserProfile(id: uid, name: displayName ?? "User", email: email ?? "")
                try await userRepository.saveProfile(defaultProfile)
                profile = defaultProfile
            }
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Persists the notification preference. Wiring this to actual push notifications requires
    /// an Apple Developer account and is left for a future implementation.
    func setNotificationsEnabled(_ isOn: Bool) async {
        guard var updatedProfile = profile else { return }
        let previousValue = updatedProfile.notificationsEnabled
        updatedProfile.notificationsEnabled = isOn
        profile = updatedProfile

        do {
            try await userRepository.saveProfile(updatedProfile)
        } catch {
            profile?.notificationsEnabled = previousValue
            errorMessage = "Failed to update notifications: \(error.localizedDescription)"
        }
    }
}
