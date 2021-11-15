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
    private let cache: ImageDataStore
    
    init(client: HTTPClient, cache: ImageDataStore) {
        self.client = client
        self.cache = cache
    }
    
    private func fetchCachedImage(for path: String) -> AnyPublisher<Data, MarvelError> {
        return Deferred {
            Future<Data, MarvelError> { [weak self] future in
                self?.cache.retrieve(dataForPath: path, completion: { result in
                    switch result {
                    case .failure:
                        future(.failure(MarvelError.cacheError))
                    case let .success(data):
                        guard let data = data else {
                            future(.failure(MarvelError.cacheError))
                            return
                        }
                        future(.success(data))
                    }
                })
            }
        }.eraseToAnyPublisher()
    }
    
    private func fetchNetworkImage(for path: String) -> AnyPublisher<Data, MarvelError> {
        return client.fetch(request: ImageService.load(path))
            .flatMap { [weak self] data in
                self?.storeImage(data: data, path: path) ?? Fail(error: MarvelError.serviceError).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    private func storeImage(data: Data, path: String) -> AnyPublisher<Data, MarvelError> {
        return Deferred {
            Future<Data, MarvelError> { [weak self] future in
                self?.cache.insert(data, for: path, completion: { result in
                    switch result {
                    case .failure:
                        future(.failure(MarvelError.cacheError))
                    case .success:
                        future(.success(data))
                    }
                })
            }
        }.eraseToAnyPublisher()
    }
    
    func fetch(from path: String) -> AnyPublisher<UIImage, MarvelError> {
        fetchCachedImage(for: path)
            .catch { [weak self] _ in
                return self?.fetchNetworkImage(for: path) ?? Fail(error: MarvelError.serviceError).eraseToAnyPublisher()
            }
            .flatMap { data -> AnyPublisher<UIImage, MarvelError> in
                guard let image = UIImage(data: data) else {
                    return Fail(error: MarvelError.serviceError).eraseToAnyPublisher()
                }
                return Just(image).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
}
