//
//  UserRepositoryTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import XCTest
@testable import P14_IOS_Eventorias

@MainActor
final class UserRepositoryTests: XCTestCase {

    func testFetchesAvatarFromFirestoreOnFirstCall() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        let document = collection.document("user1") as! MockDocument
        document.snapshot = MockDocumentSnapshot(AvatarDocument(avatarUrl: "https://example.com/a.png"))
        let sut = FirebaseUserRepository(firestore: firestore)

        let avatar = try await sut.avatar(for: "user1", forceRefresh: false)

        XCTAssertEqual(avatar.userId, "user1")
        XCTAssertEqual(avatar.avatarURL, URL(string: "https://example.com/a.png"))
        XCTAssertEqual(document.getDocumentCallCount, 1)
    }

    func testSecondCallForSameUserReturnsCacheWithoutHittingFirestore() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        let document = collection.document("user1") as! MockDocument
        document.snapshot = MockDocumentSnapshot(AvatarDocument(avatarUrl: "https://example.com/a.png"))
        let sut = FirebaseUserRepository(firestore: firestore)

        _ = try await sut.avatar(for: "user1", forceRefresh: false)
        _ = try await sut.avatar(for: "user1", forceRefresh: false)

        XCTAssertEqual(document.getDocumentCallCount, 1)
    }

    func testForceRefreshRefetchesFromFirestore() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        let document = collection.document("user1") as! MockDocument
        document.snapshot = MockDocumentSnapshot(AvatarDocument(avatarUrl: "https://example.com/a.png"))
        let sut = FirebaseUserRepository(firestore: firestore)

        _ = try await sut.avatar(for: "user1", forceRefresh: false)
        XCTAssertEqual(document.lastSource, .default)

        document.snapshot = MockDocumentSnapshot(AvatarDocument(avatarUrl: "https://example.com/b.png"))
        let refreshed = try await sut.avatar(for: "user1", forceRefresh: true)

        XCTAssertEqual(document.getDocumentCallCount, 2)
        XCTAssertEqual(refreshed.avatarURL, URL(string: "https://example.com/b.png"))
        XCTAssertEqual(document.lastSource, .server)
    }

    func testDifferentUsersAreCachedIndependently() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        (collection.document("user1") as! MockDocument).snapshot = MockDocumentSnapshot(AvatarDocument(avatarUrl: "https://example.com/a.png"))
        (collection.document("user2") as! MockDocument).snapshot = MockDocumentSnapshot(AvatarDocument(avatarUrl: "https://example.com/b.png"))
        let sut = FirebaseUserRepository(firestore: firestore)

        let avatar1 = try await sut.avatar(for: "user1", forceRefresh: false)
        let avatar2 = try await sut.avatar(for: "user2", forceRefresh: false)

        XCTAssertEqual(avatar1.avatarURL, URL(string: "https://example.com/a.png"))
        XCTAssertEqual(avatar2.avatarURL, URL(string: "https://example.com/b.png"))
    }

    func testFetchProfileReturnsNilWhenDocumentDoesNotDecode() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        let document = collection.document("user1") as! MockDocument
        document.snapshot = MockDocumentSnapshot(AvatarDocument(avatarUrl: nil))
        let sut = FirebaseUserRepository(firestore: firestore)

        let profile = try await sut.fetchProfile(uid: "user1", forceRefresh: false)

        XCTAssertNil(profile)
    }

    func testFetchProfileReturnsDecodedProfile() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        let document = collection.document("user1") as! MockDocument
        document.snapshot = MockDocumentSnapshot(UserProfile(id: "user1", name: "Alice", email: "alice@example.com", notificationsEnabled: true))
        let sut = FirebaseUserRepository(firestore: firestore)

        let profile = try await sut.fetchProfile(uid: "user1", forceRefresh: false)

        XCTAssertEqual(profile?.name, "Alice")
        XCTAssertEqual(profile?.email, "alice@example.com")
        XCTAssertEqual(profile?.notificationsEnabled, true)
        XCTAssertEqual(document.getDocumentCallCount, 1)
    }

    func testFetchProfileSecondCallReturnsCacheWithoutHittingFirestore() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        let document = collection.document("user1") as! MockDocument
        document.snapshot = MockDocumentSnapshot(UserProfile(id: "user1", name: "Alice", email: "alice@example.com"))
        let sut = FirebaseUserRepository(firestore: firestore)

        _ = try await sut.fetchProfile(uid: "user1", forceRefresh: false)
        _ = try await sut.fetchProfile(uid: "user1", forceRefresh: false)

        XCTAssertEqual(document.getDocumentCallCount, 1)
    }

    func testFetchProfileForceRefreshRefetchesFromFirestore() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        let document = collection.document("user1") as! MockDocument
        document.snapshot = MockDocumentSnapshot(UserProfile(id: "user1", name: "Alice", email: "alice@example.com"))
        let sut = FirebaseUserRepository(firestore: firestore)

        _ = try await sut.fetchProfile(uid: "user1", forceRefresh: false)
        document.snapshot = MockDocumentSnapshot(UserProfile(id: "user1", name: "Alice Updated", email: "alice@example.com"))
        let refreshed = try await sut.fetchProfile(uid: "user1", forceRefresh: true)

        XCTAssertEqual(document.getDocumentCallCount, 2)
        XCTAssertEqual(refreshed?.name, "Alice Updated")
        XCTAssertEqual(document.lastSource, .server)
    }

    func testSaveProfileWritesToFirestoreWithMergeAndCachesResult() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        let document = collection.document("user1") as! MockDocument
        let sut = FirebaseUserRepository(firestore: firestore)
        let profile = UserProfile(id: "user1", name: "Alice", email: "alice@example.com", notificationsEnabled: true)

        try await sut.saveProfile(profile)

        XCTAssertEqual(document.setDataCallCount, 1)
        XCTAssertEqual(document.lastSetDataMerge, true)

        // Cached, so a subsequent fetch doesn't need to hit Firestore again.
        let cached = try await sut.fetchProfile(uid: "user1", forceRefresh: false)
        XCTAssertEqual(cached?.name, "Alice")
        XCTAssertEqual(document.getDocumentCallCount, 0)
    }

    func testSaveProfilePropagatesFirestoreError() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "users")
        let document = collection.document("user1") as! MockDocument
        document.setDataError = NSError(domain: "Test", code: 3, userInfo: [NSLocalizedDescriptionKey: "Write failed"])
        let sut = FirebaseUserRepository(firestore: firestore)

        do {
            try await sut.saveProfile(UserProfile(id: "user1", name: "Alice", email: "alice@example.com"))
            XCTFail("Expected save to throw")
        } catch {
            XCTAssertEqual((error as NSError).localizedDescription, "Write failed")
        }
    }
}
