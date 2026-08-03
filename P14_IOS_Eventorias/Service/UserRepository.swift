//
//  UserRepository.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation

/// Caches what EventRowView needs about a user (id and avatar URL), and what the profile
/// screen needs (the full `UserProfile` document).
@MainActor
protocol UserRepositoryProtocol: Sendable {
    func avatar(for userId: String, forceRefresh: Bool) async throws -> UserAvatar
    /// Returns `nil` when the user has no profile document yet, so callers can create a default one.
    func fetchProfile(uid: String, forceRefresh: Bool) async throws -> UserProfile?
    func saveProfile(_ profile: UserProfile) async throws
}

@MainActor
final class FirebaseUserRepository: UserRepositoryProtocol {
    private let firestore: FirestoreServiceProtocol
    private var avatarCache: [String: UserAvatar] = [:]
    private var profileCache: [String: UserProfile] = [:]

    init(firestore: FirestoreServiceProtocol? = nil) {
        self.firestore = firestore ?? DefaultFirestoreService()
    }

    func avatar(for userId: String, forceRefresh: Bool) async throws -> UserAvatar {
        if !forceRefresh, let cached = avatarCache[userId] {
            return cached
        }

        let snapshot = try await firestore.collection("users").document(userId).getDocument(source: forceRefresh ? .server : .default)
        let avatarUrlString = try? snapshot.data(as: AvatarDocument.self).avatarUrl
        let avatar = UserAvatar(userId: userId, avatarURL: avatarUrlString.flatMap(URL.init(string:)))
        avatarCache[userId] = avatar
        return avatar
    }

    func fetchProfile(uid: String, forceRefresh: Bool) async throws -> UserProfile? {
        if !forceRefresh, let cached = profileCache[uid] {
            return cached
        }

        let snapshot = try await firestore.collection("users").document(uid).getDocument(source: forceRefresh ? .server : .default)
        guard let profile = try? snapshot.data(as: UserProfile.self) else {
            return nil
        }
        profileCache[uid] = profile
        return profile
    }

    func saveProfile(_ profile: UserProfile) async throws {
        guard let uid = profile.id else { return }
        try await firestore.collection("users").document(uid).setData(from: profile, merge: true)
        profileCache[uid] = profile
    }
}

@MainActor
struct AvatarDocument: Decodable {
    let avatarUrl: String?
}
