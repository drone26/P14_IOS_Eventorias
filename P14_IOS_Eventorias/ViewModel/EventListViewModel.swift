//
//  EventListViewModel.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import Observation

enum SortOption: String, CaseIterable {
    case dateAsc = "Date (Proche)"
    case dateDesc = "Date (Éloigné)"
    case titleAsc = "Titre (A-Z)"
}

@MainActor
@Observable
final class EventListViewModel {
    private(set) var events: [Event] = []
    var searchQuery: String = "" {
        didSet { applyFilters() }
    }
    var sortOption: SortOption = .dateAsc {
        didSet { applyFilters() }
    }
    var isLoading = false
    var errorMessage: String?

    private let eventRepository: EventRepositoryProtocol
    private var allEvents: [Event] = []

    init(eventRepository: EventRepositoryProtocol? = nil) {
        self.eventRepository = eventRepository ?? FirebaseEventRepository()
    }

    func loadEvents(forceRefresh: Bool = false) async {
        if !forceRefresh {
            isLoading = true
        }
        errorMessage = nil

        do {
            allEvents = try await eventRepository.events(forceRefresh: forceRefresh)
            applyFilters()
        } catch {
            errorMessage = "Erreur de chargement : \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func applyFilters() {
        var result = allEvents

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(query) }
        }

        switch sortOption {
        case .dateAsc:
            result.sort { $0.date < $1.date }
        case .dateDesc:
            result.sort { $0.date > $1.date }
        case .titleAsc:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }

        events = result
    }
}
