//
//  EventListViewModelTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import XCTest
@testable import P14_IOS_Eventorias

@MainActor
final class EventListViewModelTests: XCTestCase {

    private func makeEvent(title: String, date: Date) -> Event {
        Event(title: title, description: "Desc", date: date, address: "Addr", creatorId: "creator")
    }

    func testLoadEventsPopulatesEventsSortedByDateAscendingByDefault() async {
        let mockRepository = MockEventRepository()
        mockRepository.eventsToReturn = [
            makeEvent(title: "Later", date: Date(timeIntervalSince1970: 200)),
            makeEvent(title: "Earlier", date: Date(timeIntervalSince1970: 100))
        ]
        let sut = EventListViewModel(eventRepository: mockRepository)

        await sut.loadEvents()

        XCTAssertEqual(sut.events.map(\.title), ["Earlier", "Later"])
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockRepository.lastForceRefresh, false)
    }

    func testRefreshPassesForceRefreshTrueToRepository() async {
        let mockRepository = MockEventRepository()
        let sut = EventListViewModel(eventRepository: mockRepository)

        await sut.loadEvents(forceRefresh: true)

        XCTAssertEqual(mockRepository.lastForceRefresh, true)
    }

    func testLoadEventsFailureSetsErrorMessage() async {
        let mockRepository = MockEventRepository()
        mockRepository.error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network down"])
        let sut = EventListViewModel(eventRepository: mockRepository)

        await sut.loadEvents()

        XCTAssertTrue(sut.events.isEmpty)
        XCTAssertEqual(sut.errorMessage, "Loading error: Network down")
        XCTAssertFalse(sut.isLoading)
    }

    func testSearchQueryFiltersEventsByTitleCaseInsensitively() async {
        let mockRepository = MockEventRepository()
        mockRepository.eventsToReturn = [
            makeEvent(title: "Music Festival", date: Date(timeIntervalSince1970: 100)),
            makeEvent(title: "Art Expo", date: Date(timeIntervalSince1970: 200))
        ]
        let sut = EventListViewModel(eventRepository: mockRepository)
        await sut.loadEvents()

        sut.searchQuery = "music"

        XCTAssertEqual(sut.events.map(\.title), ["Music Festival"])
    }

    func testSortOptionTitleAscSortsAlphabetically() async {
        let mockRepository = MockEventRepository()
        mockRepository.eventsToReturn = [
            makeEvent(title: "Zebra Show", date: Date(timeIntervalSince1970: 100)),
            makeEvent(title: "Art Expo", date: Date(timeIntervalSince1970: 200))
        ]
        let sut = EventListViewModel(eventRepository: mockRepository)
        await sut.loadEvents()

        sut.sortOption = .titleAsc

        XCTAssertEqual(sut.events.map(\.title), ["Art Expo", "Zebra Show"])
    }

    func testSortOptionDateDescSortsMostRecentFirst() async {
        let mockRepository = MockEventRepository()
        mockRepository.eventsToReturn = [
            makeEvent(title: "Earlier", date: Date(timeIntervalSince1970: 100)),
            makeEvent(title: "Later", date: Date(timeIntervalSince1970: 200))
        ]
        let sut = EventListViewModel(eventRepository: mockRepository)
        await sut.loadEvents()

        sut.sortOption = .dateDesc

        XCTAssertEqual(sut.events.map(\.title), ["Later", "Earlier"])
    }
}
