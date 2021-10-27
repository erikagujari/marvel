//
//  ImageLoaderUseCase.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 26/10/21.
//

import Combine
import UIKit

protocol ImageLoaderUseCase {
    func fetch(from path: String) -> AnyPublisher<UIImage, MarvelError>
}

final class ImageLoaderProvider: ImageLoaderUseCase {
    private let client: HTTPClient
    private let cache: NSCache<NSString, UIImage>
    
    init(client: HTTPClient, cache: NSCache<NSString, UIImage>) {
        self.client = client
        self.cache = cache
    }
    
    func fetch(from path: String) -> AnyPublisher<UIImage, MarvelError> {
        guard let cachedImage = cache.object(forKey: path as NSString) else {
            return client.fetch(request: ImageService.load(path))
                .flatMap { [weak self] data -> AnyPublisher<UIImage, MarvelError> in
                    guard let image = UIImage(data: data) else {
                        return Fail<UIImage, MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher()
                    }
                    
                    self?.cache.setObject(image, forKey: path as NSString)
                    return Just(image).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
                }.eraseToAnyPublisher()
        }
        
        return Just(cachedImage).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
    }
}
