//
//  EventTests.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import XCTest
@testable import P14_IOS_Eventorias

@MainActor
final class EventTests: XCTestCase {

    private func makeEvent(id: String, title: String) -> Event {
        Event(id: id, title: title, description: "Desc", date: Date(timeIntervalSince1970: 0), address: "Addr", creatorId: "creator")
    }

    // ForEach/List use Event's Equatable conformance as a diffing hint to decide whether a row
    // needs to be re-rendered. If two Events with the same id but a different title compared
    // equal, SwiftUI would skip redrawing a row whose Firestore document was edited elsewhere
    // (e.g. via the console) but kept the same document id — exactly what pull-to-refresh needs
    // to surface.
    func testEventsWithSameIdButDifferentTitleAreNotEqual() {
        let original = makeEvent(id: "doc1", title: "Test 1")
        let edited = makeEvent(id: "doc1", title: "Test test 1")

        XCTAssertNotEqual(original, edited)
    }

    func testEventsWithSameIdAndAllFieldsEqualAreEqual() {
        let a = makeEvent(id: "doc1", title: "Test 1")
        let b = makeEvent(id: "doc1", title: "Test 1")

        XCTAssertEqual(a, b)
    }
}
