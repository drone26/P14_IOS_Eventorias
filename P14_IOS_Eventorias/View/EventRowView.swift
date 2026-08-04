//
//  EventRowView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import SwiftUI

struct EventRowView: View {
    let event: Event

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 16) {
                CreatorAvatarView(creatorId: event.creatorId, size: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text(event.address)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .lineLimit(1)

                    Text(event.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                Spacer()
            }
            .padding()

            coverImage
        }
        .frame(height: 80)
        .background(AppTheme.rowBackground)
        .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusMedium))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var coverImage: some View {
        if let imageUrl = event.coverImageUrl, let url = URL(string: imageUrl) {
            if let cachedImage = LocalImageCache.shared.getImage(for: imageUrl) {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120)
                    .clipped()
                    .accessibilityLabel("Cover photo")
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.3)
                            .overlay(ProgressView())
                            .accessibilityLabel("Loading cover photo")
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .accessibilityLabel("Cover photo")
                    case .failure:
                        Color.gray.opacity(0.3)
                            .overlay(Image(systemName: "exclamationmark.triangle").foregroundStyle(.red))
                            .accessibilityLabel("Cover photo unavailable")
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 120)
                .clipped()
            }
        } else {
            Color.gray.opacity(0.3)
                .frame(width: 120)
                .overlay(Image(systemName: "photo").foregroundStyle(.gray))
                .accessibilityLabel("No cover photo")
        }
    }
}

#Preview {
    EventRowView(event: Event(title: "Music festival", description: "Awesome music", date: Date.now, address: "123 Street", creatorId: "user1", coverImageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&q=80&w=400"))
        .padding()
        .background(Color.black)
}
