//
//  LocalImageCache.swift
//  P14_IOS_Eventorias
//
//  Created by Mathieu ARRIO on 02/08/2026.
//

import UIKit

final class LocalImageCache: @unchecked Sendable {
    static let shared = LocalImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func setImage(_ image: UIImage, for urlString: String) {
        cache.setObject(image, forKey: urlString as NSString)
    }

    func getImage(for urlString: String) -> UIImage? {
        cache.object(forKey: urlString as NSString)
    }
}
