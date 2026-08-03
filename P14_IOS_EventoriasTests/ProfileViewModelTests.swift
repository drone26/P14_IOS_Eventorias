//
//  ProfileViewModelTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import XCTest
@testable import P14_IOS_Eventorias

@MainActor
final class ProfileViewModelTests: XCTestCase {

    private func makeSUT(userRepository: MockUserRepository? = nil) -> (ProfileViewModel, MockUserRepository) {
        let repository = userRepository ?? MockUserRepository()
        return (ProfileViewModel(userRepository: repository), repository)
    }

    func testLoadProfileWithoutUidSetsErrorMessage() async {
        let (sut, userRepository) = makeSUT()

        await sut.loadProfile(uid: nil, displayName: nil, email: nil)

        XCTAssertEqual(sut.errorMessage, "User not logged in.")
        XCTAssertNil(sut.profile)
        XCTAssertEqual(userRepository.fetchProfileCallCount, 0)
    }

    func testLoadProfileReturnsExistingProfile() async {
        let userRepository = MockUserRepository()
        userRepository.profileToReturn = UserProfile(id: "user1", name: "Alice", email: "alice@example.com", notificationsEnabled: true)
        let (sut, _) = makeSUT(userRepository: userRepository)

        await sut.loadProfile(uid: "user1", displayName: "Ignored", email: "ignored@example.com")

        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.profile?.name, "Alice")
        XCTAssertEqual(sut.profile?.notificationsEnabled, true)
        XCTAssertTrue(userRepository.savedProfiles.isEmpty)
    }

    func testLoadProfileCreatesDefaultProfileWhenNoneExists() async {
        let (sut, userRepository) = makeSUT()

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
        let (sut, _) = makeSUT(userRepository: userRepository)

        await sut.loadProfile(uid: "user1", displayName: "Bob", email: "bob@example.com")

        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Failed to load profile: Fetch failed")
        XCTAssertNil(sut.profile)
    }

    func testSetNotificationsEnabledUpdatesProfileAndPersists() async {
        let userRepository = MockUserRepository()
        userRepository.profileToReturn = UserProfile(id: "user1", name: "Alice", email: "alice@example.com", notificationsEnabled: false)
        let (sut, _) = makeSUT(userRepository: userRepository)
        await sut.loadProfile(uid: "user1", displayName: "Alice", email: "alice@example.com")

        await sut.setNotificationsEnabled(true)

        XCTAssertEqual(sut.profile?.notificationsEnabled, true)
        XCTAssertEqual(userRepository.savedProfiles.last?.notificationsEnabled, true)
        XCTAssertNil(sut.errorMessage)
    }

    func testSetNotificationsEnabledRevertsOnFailure() async {
        let userRepository = MockUserRepository()
        userRepository.profileToReturn = UserProfile(id: "user1", name: "Alice", email: "alice@example.com", notificationsEnabled: false)
        let (sut, _) = makeSUT(userRepository: userRepository)
        await sut.loadProfile(uid: "user1", displayName: "Alice", email: "alice@example.com")
        userRepository.saveProfileError = NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Write failed"])

        await sut.setNotificationsEnabled(true)

        XCTAssertEqual(sut.profile?.notificationsEnabled, false)
        XCTAssertEqual(sut.errorMessage, "Failed to update notifications: Write failed")
    }

    func testSetNotificationsEnabledWithoutLoadedProfileDoesNothing() async {
        let (sut, userRepository) = makeSUT()

        await sut.setNotificationsEnabled(true)

        XCTAssertNil(sut.profile)
        XCTAssertTrue(userRepository.savedProfiles.isEmpty)
    }
}
