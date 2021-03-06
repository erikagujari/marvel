//
//  HTTPClient.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Foundation
import Combine

protocol HTTPClient {
    func fetch(request: Service) -> AnyPublisher<Data, MarvelError>
    func fetch<T: Decodable>(_ request: Service, responseType: T.Type) -> AnyPublisher<T, MarvelError>
}

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetch(request: Service) -> AnyPublisher<Data, MarvelError> {
        return session.dataTaskPublisher(for: request.urlRequest)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw MarvelError.serviceError
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw MarvelError.serviceError
                }
                
                if let string = String(data: data, encoding: .utf8) {
                    print("JSON Response:\n\(string)")
                }
                return data
            }
            .mapError { error -> MarvelError in
                switch error {
                case let error as MarvelError:
                    return error
                default:
                    return MarvelError.serviceError
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetch<T: Decodable>(_ request: Service, responseType: T.Type) -> AnyPublisher<T, MarvelError> {
        return fetch(request: request)
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error -> MarvelError in
                switch error {
                case let error as MarvelError:
                    return error
                case is DecodingError:
                    return MarvelError.mappingError
                default:
                    return MarvelError.serviceError
                }
            }
            .eraseToAnyPublisher()
    }
}
