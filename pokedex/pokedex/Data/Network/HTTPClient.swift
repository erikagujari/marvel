//
//  HTTPClient.swift
//  pokedex
//
//  Created by Erik Agujari on 23/10/21.
//
import Foundation

protocol HTTPClient: Sendable {
    func fetch(_ request: Service) async throws -> Data
    func fetch<T: Decodable>(_ request: Service, responseType: T.Type) async throws -> T
}

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(_ request: Service) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request.urlRequest)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serviceError
            }
            return data
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.serviceError
        }
    }

    func fetch<T: Decodable>(_ request: Service, responseType: T.Type) async throws -> T {
        let data = try await fetch(request)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch is DecodingError {
            throw APIError.mappingError
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.serviceError
        }
    }
}
