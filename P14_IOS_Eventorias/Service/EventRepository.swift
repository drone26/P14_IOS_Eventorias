//
//  EventRepository.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation

/// Caches the events fetched from the database. Callers control freshness with `forceRefresh`,
/// which is how the event list's pull-to-refresh gesture picks up changes made elsewhere
/// (another device, or directly in the Firebase console).
@MainActor
protocol EventRepositoryProtocol: Sendable {
    func events(forceRefresh: Bool) async throws -> [Event]
    func addEvent(_ event: Event) async throws
}

@MainActor
final class FirebaseEventRepository: EventRepositoryProtocol {
    private let firestore: FirestoreServiceProtocol
    private var cachedEvents: [Event]?

    init(firestore: FirestoreServiceProtocol? = nil) {
        self.firestore = firestore ?? DefaultFirestoreService()
    }

    func events(forceRefresh: Bool) async throws -> [Event] {
        if !forceRefresh, let cachedEvents {
            return cachedEvents
        }

        let snapshot = try await firestore.collection("events").getDocuments(source: forceRefresh ? .server : .default)
        let events = snapshot.documents.compactMap { try? $0.data(as: Event.self) }
        cachedEvents = events
        return events
    }

    func addEvent(_ event: Event) async throws {
        try await firestore.collection("events").addDocument(from: event)
        // Invalidate the cache so the next `events(forceRefresh: false)` call picks up the
        // newly created event instead of serving the stale pre-creation snapshot.
        cachedEvents = nil
    }
}
