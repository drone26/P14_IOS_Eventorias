//
//  ProfileViewModel.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class ProfileViewModel {
    var profile: UserProfile?
    var isLoading = false
    var errorMessage: String?
    var selectedAvatarImage: UIImage?
    var isUpdatingAvatar = false

    private let userRepository: UserRepositoryProtocol
    private let storageService: ImageStorageServiceProtocol

    init(userRepository: UserRepositoryProtocol? = nil, storageService: ImageStorageServiceProtocol? = nil) {
        self.userRepository = userRepository ?? FirebaseUserRepository()
        self.storageService = storageService ?? FirebaseImageStorageService()
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

    /// Uploads the picked image, then updates and persists the profile's avatar URL. Shows the
    /// picked image immediately (kept even after success) so the avatar doesn't wait on a
    /// network round trip to refresh.
    func updateAvatar(_ image: UIImage) async {
        guard var updatedProfile = profile else { return }

        let previousImage = selectedAvatarImage
        selectedAvatarImage = image
        isUpdatingAvatar = true
        errorMessage = nil

        do {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw ImageProcessingError.encodingFailed
            }

            let path = "avatar_images/\(updatedProfile.id ?? UUID().uuidString).jpg"
            let url = try await storageService.uploadImage(imageData, path: path)
            LocalImageCache.shared.setImage(image, for: url.absoluteString)

            updatedProfile.avatarUrl = url.absoluteString
            try await userRepository.saveProfile(updatedProfile)
            profile = updatedProfile
        } catch {
            selectedAvatarImage = previousImage
            errorMessage = "Failed to update avatar: \(error.localizedDescription)"
        }

        isUpdatingAvatar = false
    }
}
