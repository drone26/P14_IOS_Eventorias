//
//  EventCreationViewModel.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import UIKit
import Observation

@MainActor
@Observable
final class EventCreationViewModel {
    var title = ""
    var description = ""
    var date = Date.now
    var address = ""
    var selectedImage: UIImage?

    var isLoading = false
    var errorMessage: String?

    private let eventRepository: EventRepositoryProtocol
    private let storageService: ImageStorageServiceProtocol

    init(eventRepository: EventRepositoryProtocol? = nil, storageService: ImageStorageServiceProtocol? = nil) {
        self.eventRepository = eventRepository ?? FirebaseEventRepository()
        self.storageService = storageService ?? FirebaseImageStorageService()
    }

    /// Returns whether the event was created successfully, so the view can dismiss on success
    /// while leaving `errorMessage` on screen otherwise.
    @discardableResult
    func createEvent(creatorId: String?) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedDescription.isEmpty, !trimmedAddress.isEmpty else {
            errorMessage = "Please fill in all fields."
            return false
        }

        guard let creatorId else {
            errorMessage = "User not logged in."
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            let coverImageUrl = try await uploadSelectedImageIfNeeded()
            let event = Event(
                title: trimmedTitle,
                description: trimmedDescription,
                date: date,
                address: trimmedAddress,
                creatorId: creatorId,
                coverImageUrl: coverImageUrl
            )
            try await eventRepository.addEvent(event)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to save event: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    private func uploadSelectedImageIfNeeded() async throws -> String? {
        guard let selectedImage else { return nil }

        guard let imageData = selectedImage.jpegData(compressionQuality: 0.8) else {
            throw ImageProcessingError.encodingFailed
        }

        let path = "event_images/\(UUID().uuidString).jpg"
        let url = try await storageService.uploadImage(imageData, path: path)
        // Pre-warms the cache so the list/detail views show the cover image instantly
        // instead of waiting on a network round trip right after creation.
        LocalImageCache.shared.setImage(selectedImage, for: url.absoluteString)
        return url.absoluteString
    }
}

enum ImageProcessingError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: "Could not process the selected image."
        }
    }
}
