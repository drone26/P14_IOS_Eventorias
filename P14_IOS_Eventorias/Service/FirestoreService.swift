//
//  FirestoreService.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocol definitions

/// Mirrors Firebase's `FirestoreSource` without leaking the Firebase type into the abstraction,
/// so repositories can request a genuine server round-trip (bypassing both our own in-memory
/// cache and Firestore's local persistence) when the caller explicitly asks for a refresh.
enum FirestoreFetchSource: Sendable, Equatable {
    case `default`
    case server
    case cache
}

/// Thin abstraction over Firestore so repositories can be unit tested against a mock database.
@MainActor
protocol FirestoreDocumentSnapshotProtocol: Sendable {
    func data<T: Decodable>(as type: T.Type) throws -> T
}

@MainActor
protocol FirestoreQuerySnapshotProtocol: Sendable {
    var documents: [FirestoreDocumentSnapshotProtocol] { get }
}

@MainActor
protocol FirestoreDocumentProtocol: Sendable {
    func getDocument(source: FirestoreFetchSource) async throws -> FirestoreDocumentSnapshotProtocol
    func setData<T: Encodable>(from value: T, merge: Bool) async throws
}

@MainActor
protocol FirestoreCollectionProtocol: Sendable {
    func getDocuments(source: FirestoreFetchSource) async throws -> FirestoreQuerySnapshotProtocol
    func document(_ documentPath: String) -> FirestoreDocumentProtocol
    func addDocument<T: Encodable>(from value: T) async throws
}

@MainActor
protocol FirestoreServiceProtocol: Sendable {
    func collection(_ collectionPath: String) -> FirestoreCollectionProtocol
}

// MARK: - Default Firebase-backed implementations

@MainActor
final class DefaultFirestoreDocumentSnapshot: FirestoreDocumentSnapshotProtocol {
    private let snapshot: DocumentSnapshot
    init(_ snapshot: DocumentSnapshot) { self.snapshot = snapshot }
    func data<T: Decodable>(as type: T.Type) throws -> T {
        try snapshot.data(as: type)
    }
}

@MainActor
final class DefaultFirestoreQuerySnapshot: FirestoreQuerySnapshotProtocol {
    private let snapshot: QuerySnapshot
    init(_ snapshot: QuerySnapshot) { self.snapshot = snapshot }
    var documents: [FirestoreDocumentSnapshotProtocol] {
        snapshot.documents.map { DefaultFirestoreDocumentSnapshot($0) }
    }
}

@MainActor
final class DefaultFirestoreDocument: FirestoreDocumentProtocol {
    private let reference: DocumentReference
    init(_ reference: DocumentReference) { self.reference = reference }
    func getDocument(source: FirestoreFetchSource) async throws -> FirestoreDocumentSnapshotProtocol {
        DefaultFirestoreDocumentSnapshot(try await reference.getDocument(source: source.firestoreSource))
    }
    func setData<T: Encodable>(from value: T, merge: Bool) async throws {
        // Mirrors addDocument's manual encode step to reach the SDK's raw async setData overload.
        let encoded = try Firestore.Encoder().encode(value)
        try await reference.setData(encoded, merge: merge)
    }
}

@MainActor
final class DefaultFirestoreCollection: FirestoreCollectionProtocol {
    private let reference: CollectionReference
    init(_ reference: CollectionReference) { self.reference = reference }
    func getDocuments(source: FirestoreFetchSource) async throws -> FirestoreQuerySnapshotProtocol {
        DefaultFirestoreQuerySnapshot(try await reference.getDocuments(source: source.firestoreSource))
    }
    func document(_ documentPath: String) -> FirestoreDocumentProtocol {
        DefaultFirestoreDocument(reference.document(documentPath))
    }
    func addDocument<T: Encodable>(from value: T) async throws {
        // CollectionReference's Codable convenience only ships a synchronous/completion-handler
        // overload, so the encode step is done manually to reach the SDK's raw async `addDocument`.
        let encoded = try Firestore.Encoder().encode(value)
        _ = try await reference.addDocument(data: encoded)
    }
}

private extension FirestoreFetchSource {
    var firestoreSource: FirestoreSource {
        switch self {
        case .default: .default
        case .server: .server
        case .cache: .cache
        }
    }
}

@MainActor
final class DefaultFirestoreService: FirestoreServiceProtocol {
    private let firestore: Firestore
    init(_ firestore: Firestore = Firestore.firestore()) { self.firestore = firestore }
    func collection(_ collectionPath: String) -> FirestoreCollectionProtocol {
        DefaultFirestoreCollection(firestore.collection(collectionPath))
    }
}
