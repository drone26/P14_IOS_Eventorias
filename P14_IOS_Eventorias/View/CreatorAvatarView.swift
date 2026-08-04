//
//  CreatorAvatarView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import SwiftUI

/// Circular avatar for an event's creator, resolved through UserRepositoryProtocol.
/// Falls back to a person placeholder while loading or when no avatar is set.
struct CreatorAvatarView: View {
    let creatorId: String
    var size: CGFloat = 40
    var userRepository: UserRepositoryProtocol?

    @State private var uiImage: UIImage?
    @State private var hasAvatarURL = false

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel("Creator avatar photo")
            } else if hasAvatarURL {
                placeholder.overlay(ProgressView())
                    .accessibilityLabel("Creator avatar loading")
            } else {
                placeholder
                    .accessibilityLabel("Creator avatar placeholder")
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityIdentifier("creator_avatar")
        .task(id: creatorId) {
            await loadAvatar()
        }
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.gray.opacity(0.5))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(.white)
            )
    }

    private func loadAvatar() async {
        // Firebase isn't configured in SwiftUI previews; avoid touching it there.
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else { return }
        // Firestore throws on an empty document path; this happens transiently when a view
        // re-renders with no signed-in user (e.g. right after sign out) before it's dismissed.
        guard !creatorId.isEmpty else { return }

        let repository = userRepository ?? FirebaseUserRepository()
        guard let avatar = try? await repository.avatar(for: creatorId, forceRefresh: false),
              let url = avatar.avatarURL else { return }

        hasAvatarURL = true

        if let cached = LocalImageCache.shared.getImage(for: url.absoluteString) {
            uiImage = cached
            return
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return }
        LocalImageCache.shared.setImage(image, for: url.absoluteString)
        uiImage = image
    }
}

#Preview {
    CreatorAvatarView(creatorId: "preview-user")
        .padding()
        .background(Color.black)
}
