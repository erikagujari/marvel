//
//  ImageLoaderUseCase.swift
//  pokedex
//
//  Created by Erik Agujari on 26/10/21.
//

import UIKit

protocol ImageLoaderUseCase: Sendable {
    func fetch(from path: String) async throws -> UIImage
}

final class ImageLoaderProvider: ImageLoaderUseCase {
    private let client: HTTPClient
    private let cache: ImageDataStore

    init(client: HTTPClient, cache: ImageDataStore) {
        self.client = client
        self.cache = cache
    }

    func fetch(from path: String) async throws -> UIImage {
        if let cachedData = try? await cache.retrieve(dataForPath: path),
           let image = UIImage(data: cachedData) {
            return image
        }

        let data = try await client.fetch(ImageService.load(path))
        try? await cache.insert(data, for: path)
        guard let image = UIImage(data: data) else {
            throw APIError.serviceError
        }
        return image
    }
}
