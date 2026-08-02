//
//  Event.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import FirebaseFirestore

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
