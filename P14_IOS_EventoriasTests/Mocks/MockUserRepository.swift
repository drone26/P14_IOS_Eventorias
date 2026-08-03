//
//  MockUserRepository.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
@testable import P14_IOS_Eventorias

final class MockUserRepository: UserRepositoryProtocol, @unchecked Sendable {
    var avatarToReturn: UserAvatar = UserAvatar(userId: "", avatarURL: nil)
    var error: Error?
    private(set) var avatarCallCount = 0

    var profileToReturn: UserProfile?
    var fetchProfileError: Error?
    var saveProfileError: Error?
    private(set) var fetchProfileCallCount = 0
    private(set) var savedProfiles: [UserProfile] = []

    func avatar(for userId: String, forceRefresh: Bool) async throws -> UserAvatar {
        avatarCallCount += 1
        if let error { throw error }
        return avatarToReturn
    }

    func fetchProfile(uid: String, forceRefresh: Bool) async throws -> UserProfile? {
        fetchProfileCallCount += 1
        if let fetchProfileError { throw fetchProfileError }
        return profileToReturn
    }

    func saveProfile(_ profile: UserProfile) async throws {
        if let saveProfileError { throw saveProfileError }
        savedProfiles.append(profile)
        profileToReturn = profile
    }
}
