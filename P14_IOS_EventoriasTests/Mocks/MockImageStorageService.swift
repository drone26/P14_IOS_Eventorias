//
//  MockImageStorageService.swift
//  P14_IOS_EventoriasTests
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import Foundation
@testable import P14_IOS_Eventorias

final class MockImageStorageService: ImageStorageServiceProtocol, @unchecked Sendable {
    var urlToReturn = URL(string: "https://example.com/image.jpg")!
    var error: Error?
    private(set) var uploadCallCount = 0
    private(set) var lastUploadedData: Data?
    private(set) var lastPath: String?

    func uploadImage(_ data: Data, path: String) async throws -> URL {
        uploadCallCount += 1
        lastUploadedData = data
        lastPath = path
        if let error { throw error }
        return urlToReturn
    }
}
