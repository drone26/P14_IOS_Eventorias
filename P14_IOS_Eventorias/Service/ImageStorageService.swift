//
//  ImageStorageService.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
import FirebaseStorage

@MainActor
protocol ImageStorageServiceProtocol: Sendable {
    func uploadImage(_ data: Data, path: String) async throws -> URL
}

@MainActor
final class FirebaseImageStorageService: ImageStorageServiceProtocol {
    private let storage: Storage

    init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    func uploadImage(_ data: Data, path: String) async throws -> URL {
        let reference = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await reference.putDataAsync(data, metadata: metadata)
        return try await reference.downloadURL()
    }
}
