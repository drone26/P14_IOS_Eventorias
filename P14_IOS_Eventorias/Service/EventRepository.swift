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
protocol EventRepositoryProtocol: Sendable {
    func events(forceRefresh: Bool) async throws -> [Event]
}

actor FirebaseEventRepository: EventRepositoryProtocol {
    private let firestore: FirestoreServiceProtocol
    private var cachedEvents: [Event]?

    init(firestore: FirestoreServiceProtocol = DefaultFirestoreService()) {
        self.firestore = firestore
    }

    func events(forceRefresh: Bool) async throws -> [Event] {
        if !forceRefresh, let cachedEvents {
            return cachedEvents
        }

        let snapshot = try await firestore.collection("events").getDocuments()
        let events = snapshot.documents.compactMap { try? $0.data(as: Event.self) }
        cachedEvents = events
        return events
    }
}
