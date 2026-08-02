//
//  EventCreationViewModelTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import XCTest
import UIKit
@testable import P14_IOS_Eventorias

@MainActor
final class EventCreationViewModelTests: XCTestCase {

    private func makeSUT(eventRepository: MockEventRepository? = nil, storageService: MockImageStorageService? = nil) -> EventCreationViewModel {
        EventCreationViewModel(eventRepository: eventRepository ?? MockEventRepository(), storageService: storageService ?? MockImageStorageService())
    }

    private func fillValidFields(_ sut: EventCreationViewModel) {
        sut.title = "Concert"
        sut.description = "Live music"
        sut.address = "1 Infinite Loop, Cupertino, CA"
    }

    func testEmptyFieldsSetsErrorMessageAndDoesNotSave() async {
        let eventRepository = MockEventRepository()
        let sut = makeSUT(eventRepository: eventRepository)

        let success = await sut.createEvent(creatorId: "user1")

        XCTAssertFalse(success)
        XCTAssertEqual(sut.errorMessage, "Please fill in all fields.")
        XCTAssertTrue(eventRepository.addedEvents.isEmpty)
    }

    func testMissingCreatorIdSetsErrorMessageAndDoesNotSave() async {
        let eventRepository = MockEventRepository()
        let sut = makeSUT(eventRepository: eventRepository)
        fillValidFields(sut)

        let success = await sut.createEvent(creatorId: nil)

        XCTAssertFalse(success)
        XCTAssertEqual(sut.errorMessage, "User not logged in.")
        XCTAssertTrue(eventRepository.addedEvents.isEmpty)
    }

    func testSuccessWithoutImageSavesEventAndClearsLoading() async {
        let eventRepository = MockEventRepository()
        let sut = makeSUT(eventRepository: eventRepository)
        fillValidFields(sut)

        let success = await sut.createEvent(creatorId: "user1")

        XCTAssertTrue(success)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(eventRepository.addedEvents.count, 1)
        XCTAssertEqual(eventRepository.addedEvents.first?.title, "Concert")
        XCTAssertEqual(eventRepository.addedEvents.first?.creatorId, "user1")
        XCTAssertNil(eventRepository.addedEvents.first?.coverImageUrl)
    }

    func testSuccessWithImageUploadsThenSavesEventWithCoverImageUrl() async {
        let eventRepository = MockEventRepository()
        let storageService = MockImageStorageService()
        storageService.urlToReturn = URL(string: "https://example.com/event_images/abc.jpg")!
        let sut = makeSUT(eventRepository: eventRepository, storageService: storageService)
        fillValidFields(sut)
        sut.selectedImage = UIImage(systemName: "photo")

        let success = await sut.createEvent(creatorId: "user1")

        XCTAssertTrue(success)
        XCTAssertEqual(storageService.uploadCallCount, 1)
        XCTAssertNotNil(storageService.lastUploadedData)
        XCTAssertEqual(eventRepository.addedEvents.first?.coverImageUrl, "https://example.com/event_images/abc.jpg")
    }

    func testImageUploadFailureSetsErrorMessageAndDoesNotSaveEvent() async {
        let eventRepository = MockEventRepository()
        let storageService = MockImageStorageService()
        storageService.error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        let sut = makeSUT(eventRepository: eventRepository, storageService: storageService)
        fillValidFields(sut)
        sut.selectedImage = UIImage(systemName: "photo")

        let success = await sut.createEvent(creatorId: "user1")

        XCTAssertFalse(success)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Failed to save event: Upload failed")
        XCTAssertTrue(eventRepository.addedEvents.isEmpty)
    }

    func testSaveFailureSetsErrorMessage() async {
        let eventRepository = MockEventRepository()
        eventRepository.addEventError = NSError(domain: "Test", code: 2, userInfo: [NSLocalizedDescriptionKey: "Write failed"])
        let sut = makeSUT(eventRepository: eventRepository)
        fillValidFields(sut)

        let success = await sut.createEvent(creatorId: "user1")

        XCTAssertFalse(success)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Failed to save event: Write failed")
    }
}
