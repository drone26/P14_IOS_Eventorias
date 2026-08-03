//
//  ProfileViewModelTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import XCTest
import UIKit
@testable import P14_IOS_Eventorias

@MainActor
final class ProfileViewModelTests: XCTestCase {

    private func makeSUT(
        userRepository: MockUserRepository? = nil,
        storageService: MockImageStorageService? = nil
    ) -> (ProfileViewModel, MockUserRepository, MockImageStorageService) {
        let repository = userRepository ?? MockUserRepository()
        let storage = storageService ?? MockImageStorageService()
        return (ProfileViewModel(userRepository: repository, storageService: storage), repository, storage)
    }

    /// `UIImage()` has no backing data and produces nil `jpegData`; tests need a real 1x1 image.
    private func makeTestImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    func testLoadProfileWithoutUidSetsErrorMessage() async {
        let (sut, userRepository, _) = makeSUT()

        await sut.loadProfile(uid: nil, displayName: nil, email: nil)

        XCTAssertEqual(sut.errorMessage, "User not logged in.")
        XCTAssertNil(sut.profile)
        XCTAssertEqual(userRepository.fetchProfileCallCount, 0)
    }

    func testLoadProfileReturnsExistingProfile() async {
        let userRepository = MockUserRepository()
        userRepository.profileToReturn = UserProfile(id: "user1", name: "Alice", email: "alice@example.com", notificationsEnabled: true)
        let (sut, _, _) = makeSUT(userRepository: userRepository)

        await sut.loadProfile(uid: "user1", displayName: "Ignored", email: "ignored@example.com")

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.profile?.name, "Alice")
        XCTAssertEqual(sut.profile?.notificationsEnabled, true)
        XCTAssertTrue(userRepository.savedProfiles.isEmpty)
    }

    func testLoadProfileCreatesDefaultProfileWhenNoneExists() async {
        let (sut, userRepository, _) = makeSUT()

        await sut.loadProfile(uid: "user1", displayName: "Bob", email: "bob@example.com")

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.profile?.id, "user1")
        XCTAssertEqual(sut.profile?.name, "Bob")
        XCTAssertEqual(sut.profile?.email, "bob@example.com")
        XCTAssertEqual(sut.profile?.notificationsEnabled, false)
        XCTAssertEqual(userRepository.savedProfiles.count, 1)
    }

    func testLoadProfileFetchFailureSetsErrorMessage() async {
        let userRepository = MockUserRepository()
        userRepository.fetchProfileError = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch failed"])
        let (sut, _, _) = makeSUT(userRepository: userRepository)

        await sut.loadProfile(uid: "user1", displayName: "Bob", email: "bob@example.com")

        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Failed to load profile: Fetch failed")
        XCTAssertNil(sut.profile)
    }

    func testSetNotificationsEnabledUpdatesProfileAndPersists() async {
        let userRepository = MockUserRepository()
        userRepository.profileToReturn = UserProfile(id: "user1", name: "Alice", email: "alice@example.com", notificationsEnabled: false)
        let (sut, _, _) = makeSUT(userRepository: userRepository)
        await sut.loadProfile(uid: "user1", displayName: "Alice", email: "alice@example.com")

        await sut.setNotificationsEnabled(true)

        XCTAssertEqual(sut.profile?.notificationsEnabled, true)
        XCTAssertEqual(userRepository.savedProfiles.last?.notificationsEnabled, true)
        XCTAssertNil(sut.errorMessage)
    }

    func testSetNotificationsEnabledRevertsOnFailure() async {
        let userRepository = MockUserRepository()
        userRepository.profileToReturn = UserProfile(id: "user1", name: "Alice", email: "alice@example.com", notificationsEnabled: false)
        let (sut, _, _) = makeSUT(userRepository: userRepository)
        await sut.loadProfile(uid: "user1", displayName: "Alice", email: "alice@example.com")
        userRepository.saveProfileError = NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Write failed"])

        await sut.setNotificationsEnabled(true)

        XCTAssertEqual(sut.profile?.notificationsEnabled, false)
        XCTAssertEqual(sut.errorMessage, "Failed to update notifications: Write failed")
    }

    func testSetNotificationsEnabledWithoutLoadedProfileDoesNothing() async {
        let (sut, userRepository, _) = makeSUT()

        await sut.setNotificationsEnabled(true)

        XCTAssertNil(sut.profile)
        XCTAssertTrue(userRepository.savedProfiles.isEmpty)
    }

    func testUpdateAvatarUploadsImageAndPersistsUrl() async {
        let userRepository = MockUserRepository()
        userRepository.profileToReturn = UserProfile(id: "user1", name: "Alice", email: "alice@example.com")
        let storageService = MockImageStorageService()
        storageService.urlToReturn = URL(string: "https://example.com/avatar.jpg")!
        let (sut, _, _) = makeSUT(userRepository: userRepository, storageService: storageService)
        await sut.loadProfile(uid: "user1", displayName: "Alice", email: "alice@example.com")
        let image = makeTestImage()

        await sut.updateAvatar(image)

        XCTAssertEqual(sut.profile?.avatarUrl, "https://example.com/avatar.jpg")
        XCTAssertEqual(sut.selectedAvatarImage, image)
        XCTAssertFalse(sut.isUpdatingAvatar)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(storageService.uploadCallCount, 1)
        XCTAssertEqual(storageService.lastPath, "avatar_images/user1.jpg")
        XCTAssertEqual(userRepository.savedProfiles.last?.avatarUrl, "https://example.com/avatar.jpg")
    }

    func testUpdateAvatarRevertsOnUploadFailure() async {
        let userRepository = MockUserRepository()
        userRepository.profileToReturn = UserProfile(id: "user1", name: "Alice", email: "alice@example.com")
        let storageService = MockImageStorageService()
        storageService.error = NSError(domain: "Test", code: 3, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        let (sut, _, _) = makeSUT(userRepository: userRepository, storageService: storageService)
        await sut.loadProfile(uid: "user1", displayName: "Alice", email: "alice@example.com")

        await sut.updateAvatar(makeTestImage())

        XCTAssertNil(sut.profile?.avatarUrl)
        XCTAssertNil(sut.selectedAvatarImage)
        XCTAssertFalse(sut.isUpdatingAvatar)
        XCTAssertEqual(sut.errorMessage, "Failed to update avatar: Upload failed")
        XCTAssertTrue(userRepository.savedProfiles.isEmpty)
    }

    func testUpdateAvatarWithoutLoadedProfileDoesNothing() async {
        let (sut, userRepository, storageService) = makeSUT()

        await sut.updateAvatar(makeTestImage())

        XCTAssertNil(sut.selectedAvatarImage)
        XCTAssertEqual(storageService.uploadCallCount, 0)
        XCTAssertTrue(userRepository.savedProfiles.isEmpty)
    }
}
