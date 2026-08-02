//
//  FirestoreService.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol definitions

/// Thin abstraction over Firestore so repositories can be unit tested against a mock database.
protocol FirestoreDocumentSnapshotProtocol: Sendable {
    func data<T: Decodable>(as type: T.Type) throws -> T
}

protocol FirestoreQuerySnapshotProtocol: Sendable {
    var documents: [FirestoreDocumentSnapshotProtocol] { get }
}

protocol FirestoreDocumentProtocol: Sendable {
    func getDocument() async throws -> FirestoreDocumentSnapshotProtocol
}

protocol FirestoreCollectionProtocol: Sendable {
    func getDocuments() async throws -> FirestoreQuerySnapshotProtocol
    func document(_ documentPath: String) -> FirestoreDocumentProtocol
}

protocol FirestoreServiceProtocol: Sendable {
    func collection(_ collectionPath: String) -> FirestoreCollectionProtocol
}

// MARK: - Default Firebase-backed implementations

final class DefaultFirestoreDocumentSnapshot: @unchecked Sendable, FirestoreDocumentSnapshotProtocol {
    private let snapshot: DocumentSnapshot
    init(_ snapshot: DocumentSnapshot) { self.snapshot = snapshot }
    func data<T: Decodable>(as type: T.Type) throws -> T {
        try snapshot.data(as: type)
    }
}

final class DefaultFirestoreQuerySnapshot: @unchecked Sendable, FirestoreQuerySnapshotProtocol {
    private let snapshot: QuerySnapshot
    init(_ snapshot: QuerySnapshot) { self.snapshot = snapshot }
    var documents: [FirestoreDocumentSnapshotProtocol] {
        snapshot.documents.map { DefaultFirestoreDocumentSnapshot($0) }
    }
}

final class DefaultFirestoreDocument: @unchecked Sendable, FirestoreDocumentProtocol {
    private let reference: DocumentReference
    init(_ reference: DocumentReference) { self.reference = reference }
    func getDocument() async throws -> FirestoreDocumentSnapshotProtocol {
        DefaultFirestoreDocumentSnapshot(try await reference.getDocument())
    }
}

final class DefaultFirestoreCollection: @unchecked Sendable, FirestoreCollectionProtocol {
    private let reference: CollectionReference
    init(_ reference: CollectionReference) { self.reference = reference }
    func getDocuments() async throws -> FirestoreQuerySnapshotProtocol {
        DefaultFirestoreQuerySnapshot(try await reference.getDocuments())
    }
    func document(_ documentPath: String) -> FirestoreDocumentProtocol {
        DefaultFirestoreDocument(reference.document(documentPath))
    }
}

final class DefaultFirestoreService: @unchecked Sendable, FirestoreServiceProtocol {
    private let firestore: Firestore
    init(_ firestore: Firestore = Firestore.firestore()) { self.firestore = firestore }
    func collection(_ collectionPath: String) -> FirestoreCollectionProtocol {
        DefaultFirestoreCollection(firestore.collection(collectionPath))
    }
}
