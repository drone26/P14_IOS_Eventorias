//
//  UserAvatar.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation

/// Minimal cached representation of a user, limited to what EventRowView needs to render a creator avatar.
struct UserAvatar: Sendable, Equatable {
    let userId: String
    let avatarURL: URL?
}
