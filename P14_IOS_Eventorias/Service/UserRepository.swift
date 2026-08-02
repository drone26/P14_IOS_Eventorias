//
//  UserRepository.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation

/// Caches only what EventRowView needs about a user: their id and avatar URL.
protocol UserRepositoryProtocol: Sendable {
    func avatar(for userId: String, forceRefresh: Bool) async throws -> UserAvatar
}

actor FirebaseUserRepository: UserRepositoryProtocol {
    private let firestore: FirestoreServiceProtocol
    private var cache: [String: UserAvatar] = [:]

    init(firestore: FirestoreServiceProtocol = DefaultFirestoreService()) {
        self.firestore = firestore
    }

    func avatar(for userId: String, forceRefresh: Bool) async throws -> UserAvatar {
        if !forceRefresh, let cached = cache[userId] {
            return cached
        }

        let snapshot = try await firestore.collection("users").document(userId).getDocument()
        let avatarUrlString = try? snapshot.data(as: AvatarDocument.self).avatarUrl
        let avatar = UserAvatar(userId: userId, avatarURL: avatarUrlString.flatMap(URL.init(string:)))
        cache[userId] = avatar
        return avatar
    }
}

struct AvatarDocument: Decodable {
    let avatarUrl: String?
}
