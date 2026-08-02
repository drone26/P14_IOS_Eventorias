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

    func avatar(for userId: String, forceRefresh: Bool) async throws -> UserAvatar {
        avatarCallCount += 1
        if let error { throw error }
        return avatarToReturn
    }
}
