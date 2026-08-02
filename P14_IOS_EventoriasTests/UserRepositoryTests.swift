//
//  UserRepositoryTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import XCTest
@testable import P14_IOS_Eventorias

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

        document.snapshot = MockDocumentSnapshot(AvatarDocument(avatarUrl: "https://example.com/b.png"))
        let refreshed = try await sut.avatar(for: "user1", forceRefresh: true)

        XCTAssertEqual(document.getDocumentCallCount, 2)
        XCTAssertEqual(refreshed.avatarURL, URL(string: "https://example.com/b.png"))
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
}
