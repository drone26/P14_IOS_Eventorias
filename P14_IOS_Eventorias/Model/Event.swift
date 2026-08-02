//
//  Event.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import FirebaseFirestore

@MainActor
struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var date: Date
    var address: String
    var creatorId: String
    var coverImageUrl: String?
    var attachmentsUrls: [String]?
    @ServerTimestamp var createdAt: Date?

    init(id: String? = nil, title: String, description: String, date: Date, address: String, creatorId: String, coverImageUrl: String? = nil, attachmentsUrls: [String]? = nil, createdAt: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.address = address
        self.creatorId = creatorId
        self.coverImageUrl = coverImageUrl
        self.attachmentsUrls = attachmentsUrls
        self.createdAt = createdAt
    }
}

extension Event: Hashable {
    // Compares every field, not just `id`: ForEach/List use this conformance as a diffing
    // optimization hint, and an id-only comparison made SwiftUI skip re-rendering a row whose
    // Firestore document kept the same id but had a field (e.g. title) edited elsewhere.
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.date == rhs.date &&
        lhs.address == rhs.address &&
        lhs.creatorId == rhs.creatorId &&
        lhs.coverImageUrl == rhs.coverImageUrl &&
        lhs.attachmentsUrls == rhs.attachmentsUrls
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
