//
//  UserProfile.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import FirebaseFirestore

@MainActor
struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var avatarUrl: String?
    var notificationsEnabled: Bool

    init(id: String? = nil, name: String, email: String, avatarUrl: String? = nil, notificationsEnabled: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarUrl = avatarUrl
        self.notificationsEnabled = notificationsEnabled
    }
}
