//
//  EventDetailView.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event

    private var staticMapUrl: URL? {
        guard let encodedAddress = event.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        let urlString = "https://maps.googleapis.com/maps/api/staticmap?center=\(encodedAddress)&zoom=15&size=400x200&markers=color:red%7C\(encodedAddress)&key=\(APIKeys.googleMapsStaticAPIKey)"
        return URL(string: urlString)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    coverImage

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                Text(event.date, style: .date)
                            } icon: {
                                Image(systemName: "calendar")
                                    .frame(width: 20)
                                    .accessibilityHidden(true)
                            }
                            Label {
                                Text(event.date, style: .time)
                            } icon: {
                                Image(systemName: "clock")
                                    .frame(width: 20)
                                    .accessibilityHidden(true)
                            }
                        }
                        .font(.title3)
                        .foregroundStyle(.white)

                        Spacer()

                        CreatorAvatarView(creatorId: event.creatorId, size: 60)
                    }
                    .padding(.top, 8)

                    Text(event.description)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(4)
                        .padding(.top, 8)
                        .accessibilityIdentifier("event_detail_description")

                    HStack(alignment: .top, spacing: 16) {
                        Text(event.address)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("event_detail_address")

                        staticMap
                    }
                    .padding(.top, 16)
                }
                .padding()
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var coverImage: some View {
        if let imageUrl = event.coverImageUrl, let url = URL(string: imageUrl) {
            if let cachedImage = LocalImageCache.shared.getImage(for: imageUrl) {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .overlay(
                        Image(uiImage: cachedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    )
                    .clipped()
                    .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusMedium))
                    .shadow(radius: 5)
                    .accessibilityLabel("Event cover photo")
                    .accessibilityAddTraits(.isImage)
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .overlay(
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(ProgressView())
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(Image(systemName: "photo").foregroundStyle(.gray).accessibilityHidden(true))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    )
                    .clipped()
                    .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusMedium))
                    .shadow(radius: 5)
                    .accessibilityLabel("Event cover photo")
                    .accessibilityAddTraits(.isImage)
            }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusMedium))
                .overlay(Image(systemName: "photo").foregroundStyle(.gray).accessibilityHidden(true))
                .accessibilityLabel("Event cover photo")
                .accessibilityAddTraits(.isImage)
        }
    }

    @ViewBuilder
    private var staticMap: some View {
        if let mapUrl = staticMapUrl {
            AsyncImage(url: mapUrl) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(Text("Map Error").font(.caption).foregroundStyle(.gray))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 140, height: 80)
            .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusMedium))
            .clipped()
            .accessibilityLabel("Static map showing event location")
            .accessibilityAddTraits(.isImage)
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 140, height: 80)
                .clipShape(.rect(cornerRadius: AppTheme.cornerRadiusMedium))
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: Event(title: "Music festival", description: "Awesome music all night long, with great artists and a wonderful atmosphere.", date: .now, address: "1 Infinite Loop, Cupertino, CA", creatorId: "preview-user", coverImageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?auto=format&fit=crop&q=80&w=400"))
    }
}
