//
//  MockEventRepository.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
@testable import P14_IOS_Eventorias

final class MockEventRepository: EventRepositoryProtocol, @unchecked Sendable {
    var eventsToReturn: [Event] = []
    var error: Error?
    private(set) var eventsCallCount = 0
    private(set) var lastForceRefresh: Bool?

    var addEventError: Error?
    private(set) var addedEvents: [Event] = []

    func events(forceRefresh: Bool) async throws -> [Event] {
        eventsCallCount += 1
        lastForceRefresh = forceRefresh
        if let error { throw error }
        return eventsToReturn
    }

    func addEvent(_ event: Event) async throws {
        addedEvents.append(event)
        if let addEventError { throw addEventError }
    }
}
