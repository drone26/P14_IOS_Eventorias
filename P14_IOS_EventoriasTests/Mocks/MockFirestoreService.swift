//
//  MockFirestoreService.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
@testable import P14_IOS_Eventorias

/// Directly injects a pre-decoded value instead of round-tripping through JSON, since Firestore's
/// `@DocumentID` / `@ServerTimestamp` property wrappers don't decode meaningfully from plain JSON.
struct MockDocumentSnapshot: FirestoreDocumentSnapshotProtocol {
    private let value: Any

    init<T: Decodable>(_ value: T) {
        self.value = value
    }

    func data<T: Decodable>(as type: T.Type) throws -> T {
        guard let typed = value as? T else {
            throw NSError(domain: "MockDocumentSnapshot", code: -1, userInfo: [NSLocalizedDescriptionKey: "Type mismatch: expected \(T.self)"])
        }
        return typed
    }
}

struct MockQuerySnapshot: FirestoreQuerySnapshotProtocol {
    var documents: [FirestoreDocumentSnapshotProtocol]
}

final class MockDocument: FirestoreDocumentProtocol, @unchecked Sendable {
    var snapshot: FirestoreDocumentSnapshotProtocol
    var error: Error?
    private(set) var getDocumentCallCount = 0
    private(set) var lastSource: FirestoreFetchSource?

    init(snapshot: FirestoreDocumentSnapshotProtocol) {
        self.snapshot = snapshot
    }

    func getDocument(source: FirestoreFetchSource) async throws -> FirestoreDocumentSnapshotProtocol {
        getDocumentCallCount += 1
        lastSource = source
        if let error { throw error }
        return snapshot
    }
}

final class MockCollection: FirestoreCollectionProtocol, @unchecked Sendable {
    var querySnapshot: MockQuerySnapshot = MockQuerySnapshot(documents: [])
    var error: Error?
    var documentsByPath: [String: MockDocument] = [:]
    private(set) var getDocumentsCallCount = 0
    private(set) var lastSource: FirestoreFetchSource?

    var addDocumentError: Error?
    private(set) var addedDocuments: [Any] = []
    private(set) var addDocumentCallCount = 0

    func getDocuments(source: FirestoreFetchSource) async throws -> FirestoreQuerySnapshotProtocol {
        getDocumentsCallCount += 1
        lastSource = source
        if let error { throw error }
        return querySnapshot
    }

    func document(_ documentPath: String) -> FirestoreDocumentProtocol {
        if let existing = documentsByPath[documentPath] {
            return existing
        }
        let newDocument = MockDocument(snapshot: MockDocumentSnapshot(AvatarDocument(avatarUrl: nil)))
        documentsByPath[documentPath] = newDocument
        return newDocument
    }

    func addDocument<T: Encodable>(from value: T) async throws {
        addDocumentCallCount += 1
        addedDocuments.append(value)
        if let addDocumentError { throw addDocumentError }
    }
}

final class MockFirestoreService: FirestoreServiceProtocol, @unchecked Sendable {
    var collectionsByPath: [String: MockCollection] = [:]

    func collection(_ collectionPath: String) -> FirestoreCollectionProtocol {
        collection(named: collectionPath)
    }

    func collection(named collectionPath: String) -> MockCollection {
        if let existing = collectionsByPath[collectionPath] {
            return existing
        }
        let newCollection = MockCollection()
        collectionsByPath[collectionPath] = newCollection
        return newCollection
    }
}
