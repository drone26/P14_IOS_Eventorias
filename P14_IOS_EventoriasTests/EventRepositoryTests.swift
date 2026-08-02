//
//  EventRepositoryTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import XCTest
@testable import P14_IOS_Eventorias

final class EventRepositoryTests: XCTestCase {

    private func makeEvent(title: String) -> Event {
        Event(title: title, description: "Desc", date: Date(timeIntervalSince1970: 0), address: "Addr", creatorId: "creator")
    }

    func testFetchesFromFirestoreOnFirstCall() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "events")
        collection.querySnapshot = MockQuerySnapshot(documents: [
            MockDocumentSnapshot(makeEvent(title: "Concert"))
        ])
        let sut = FirebaseEventRepository(firestore: firestore)

        let events = try await sut.events(forceRefresh: false)

        XCTAssertEqual(events.map(\.title), ["Concert"])
        XCTAssertEqual(collection.getDocumentsCallCount, 1)
    }

    func testSecondCallReturnsCacheWithoutHittingFirestore() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "events")
        collection.querySnapshot = MockQuerySnapshot(documents: [
            MockDocumentSnapshot(makeEvent(title: "Concert"))
        ])
        let sut = FirebaseEventRepository(firestore: firestore)

        _ = try await sut.events(forceRefresh: false)
        _ = try await sut.events(forceRefresh: false)

        XCTAssertEqual(collection.getDocumentsCallCount, 1)
    }

    func testForceRefreshRefetchesFromFirestore() async throws {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "events")
        collection.querySnapshot = MockQuerySnapshot(documents: [
            MockDocumentSnapshot(makeEvent(title: "Concert"))
        ])
        let sut = FirebaseEventRepository(firestore: firestore)

        _ = try await sut.events(forceRefresh: false)

        collection.querySnapshot = MockQuerySnapshot(documents: [
            MockDocumentSnapshot(makeEvent(title: "Concert")),
            MockDocumentSnapshot(makeEvent(title: "Expo"))
        ])
        let refreshed = try await sut.events(forceRefresh: true)

        XCTAssertEqual(collection.getDocumentsCallCount, 2)
        XCTAssertEqual(refreshed.map(\.title), ["Concert", "Expo"])
    }

    func testFetchErrorPropagatesAndDoesNotCache() async {
        let firestore = MockFirestoreService()
        let collection = firestore.collection(named: "events")
        collection.error = NSError(domain: "Test", code: 1)
        let sut = FirebaseEventRepository(firestore: firestore)

        do {
            _ = try await sut.events(forceRefresh: false)
            XCTFail("Expected error to be thrown")
        } catch {
            // expected
        }

        collection.error = nil
        collection.querySnapshot = MockQuerySnapshot(documents: [
            MockDocumentSnapshot(makeEvent(title: "Concert"))
        ])
        let events = try? await sut.events(forceRefresh: false)
        XCTAssertEqual(events?.map(\.title), ["Concert"])
    }
}
