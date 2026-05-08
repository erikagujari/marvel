//
//  ImageLoaderUseCase.swift
//  pokedex
//
//  Created by Erik Agujari on 26/10/21.
//

import Combine
import UIKit

protocol ImageLoaderUseCase {
    func fetch(from path: String) -> AnyPublisher<UIImage, APIError>
}

final class ImageLoaderProvider: ImageLoaderUseCase {
    private let client: HTTPClient
    private let cache: ImageDataStore

    init(client: HTTPClient, cache: ImageDataStore) {
        self.client = client
        self.cache = cache
    }

    private func fetchCachedImage(for path: String) -> AnyPublisher<Data, APIError> {
        return Deferred {
            Future<Data, APIError> { [weak self] future in
                self?.cache.retrieve(dataForPath: path, completion: { result in
                    switch result {
                    case .failure:
                        future(.failure(APIError.cacheError))
                    case let .success(data):
                        guard let data = data else {
                            future(.failure(APIError.cacheError))
                            return
                        }
                        future(.success(data))
                    }
                })
            }
        }.eraseToAnyPublisher()
    }

    private func fetchNetworkImage(for path: String) -> AnyPublisher<Data, APIError> {
        return client.fetch(request: ImageService.load(path))
            .flatMap { [weak self] data in
                self?.storeImage(data: data, path: path) ?? Fail(error: APIError.serviceError).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func storeImage(data: Data, path: String) -> AnyPublisher<Data, APIError> {
        return Deferred {
            Future<Data, APIError> { [weak self] future in
                self?.cache.insert(data, for: path, completion: { result in
                    switch result {
                    case .failure:
                        future(.failure(APIError.cacheError))
                    case .success:
                        future(.success(data))
                    }
                })
            }
        }.eraseToAnyPublisher()
    }

    func fetch(from path: String) -> AnyPublisher<UIImage, APIError> {
        fetchCachedImage(for: path)
            .catch { [weak self] _ in
                return self?.fetchNetworkImage(for: path) ?? Fail(error: APIError.serviceError).eraseToAnyPublisher()
            }
            .flatMap { data -> AnyPublisher<UIImage, APIError> in
                guard let image = UIImage(data: data) else {
                    return Fail(error: APIError.serviceError).eraseToAnyPublisher()
                }
                return Just(image).setFailureType(to: APIError.self).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
}
