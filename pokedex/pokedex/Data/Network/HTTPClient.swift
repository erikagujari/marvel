//
//  HTTPClient.swift
//  pokedex
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine
import Foundation

protocol HTTPClient {
    func fetch(request: Service) -> AnyPublisher<Data, APIError>
    func fetch<T: Decodable>(_ request: Service, responseType: T.Type) -> AnyPublisher<T, APIError>
}

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(request: Service) -> AnyPublisher<Data, APIError> {
        return session.dataTaskPublisher(for: request.urlRequest)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.serviceError
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw APIError.serviceError
                }
                return data
            }
            .mapError { error -> APIError in
                switch error {
                case let error as APIError:
                    return error
                default:
                    return APIError.serviceError
                }
            }
            .eraseToAnyPublisher()
    }

    func fetch<T: Decodable>(_ request: Service, responseType: T.Type) -> AnyPublisher<T, APIError> {
        return fetch(request: request)
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error -> APIError in
                switch error {
                case let error as APIError:
                    return error
                case is DecodingError:
                    return APIError.mappingError
                default:
                    return APIError.serviceError
                }
            }
            .eraseToAnyPublisher()
    }
}
