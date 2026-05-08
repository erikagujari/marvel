//
//  PokemonRepositoryTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine
@testable import pokedex
import XCTest

final class PokemonRepositoryTests: XCTestCase {
    func test_fetchReturnsServiceError_onNilHTTPResponse() {
        let sut = makeSUT(data: nil, urlResponse: nil, error: nil)

        expectFetchList(sut: sut, endsWithResult: .failure(.serviceError))
        expectFetchDetail(sut: sut, endsWithResult: .failure(.serviceError))
    }

    func test_fetchReturnsServiceError_onNotHTTPURLResponse() {
        let sut = makeSUT(data: nil, urlResponse: URLResponse(), error: nil)

        expectFetchList(sut: sut, endsWithResult: .failure(.serviceError))
        expectFetchDetail(sut: sut, endsWithResult: .failure(.serviceError))
    }

    func test_fetchReturnsServiceError_on199StatusCode() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 199,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: nil, urlResponse: urlResponse, error: nil)

        expectFetchList(sut: sut, endsWithResult: .failure(.serviceError))
        expectFetchDetail(sut: sut, endsWithResult: .failure(.serviceError))
    }

    func test_fetchReturnsServiceError_on300StatusCode() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 300,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: nil, urlResponse: urlResponse, error: nil)

        expectFetchList(sut: sut, endsWithResult: .failure(.serviceError))
        expectFetchDetail(sut: sut, endsWithResult: .failure(.serviceError))
    }

    func test_fetchReturnsMappingError_onNilData() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: nil, urlResponse: urlResponse, error: nil)

        expectFetchList(sut: sut, endsWithResult: .failure(.mappingError))
        expectFetchDetail(sut: sut, endsWithResult: .failure(.mappingError))
    }

    func test_fetchReturnsMappingError_onEmptyData() {
        let data = "".data(using: .utf8)
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: data, urlResponse: urlResponse, error: nil)

        expectFetchList(sut: sut, endsWithResult: .failure(.mappingError))
        expectFetchDetail(sut: sut, endsWithResult: .failure(.mappingError))
    }

    func test_fetchReturnsMappingError_onInvalidData() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: anyInvalidJSON(), urlResponse: urlResponse, error: nil)

        expectFetchList(sut: sut, endsWithResult: .failure(.mappingError))
        expectFetchDetail(sut: sut, endsWithResult: .failure(.mappingError))
    }

    func test_fetchListReturnsPokemon_onValidListData() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: anyValidPokemonListJSON(), urlResponse: urlResponse, error: nil)

        expectFetchList(sut: sut, endsWithResult: .finished)
    }

    func test_fetchReturnsServiceError_onAnyError() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: anyValidPokemonListJSON(), urlResponse: urlResponse, error: APIError.mappingError)

        expectFetchList(sut: sut, endsWithResult: .failure(.serviceError))
        expectFetchDetail(sut: sut, endsWithResult: .failure(.serviceError))
    }

    func test_pokemonInitFromListItem_parsesIdFromURL() {
        let item = PokemonListItem(name: "bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/")
        let pokemon = Pokemon(from: item)

        XCTAssertEqual(pokemon?.id, 1)
        XCTAssertEqual(pokemon?.name, "Bulbasaur")
        XCTAssertEqual(pokemon?.imageURL, Pokemon.artworkURL(for: 1))
    }

    func test_pokemonInitFromListItem_returnsNilOnInvalidURL() {
        let item = PokemonListItem(name: "x", url: "https://pokeapi.co/api/v2/pokemon/not-a-number/")

        XCTAssertNil(Pokemon(from: item))
    }
}

private extension PokemonRepositoryTests {
    func makeSUT(data: Data? = nil, urlResponse: URLResponse? = nil, error: Error? = nil) -> PokemonRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        URLProtocolStub.data = data
        URLProtocolStub.urlResponse = urlResponse
        URLProtocolStub.error = error

        return PokemonRepositoryProvider(httpClient: URLSessionHTTPClient(session: URLSession(configuration: configuration)))
    }

    func expectFetchList(sut: PokemonRepository, endsWithResult expectedResult: Subscribers.Completion<APIError>, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Waiting to complete fetch")
        var cancellables = Set<AnyCancellable>()

        sut.fetch(offset: 0, limit: 0)
            .sink { receivedResult in
                XCTAssertEqual(expectedResult, receivedResult, file: file, line: line)
                exp.fulfill()
            } receiveValue: { pokemon in
                XCTAssertFalse(pokemon.isEmpty, file: file, line: line)
            }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 2)
    }

    func expectFetchDetail(sut: PokemonRepository, endsWithResult expectedResult: Subscribers.Completion<APIError>, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Waiting to complete fetch")
        var cancellables = Set<AnyCancellable>()

        sut.fetchDetail(id: 0)
            .sink { receivedResult in
                XCTAssertEqual(expectedResult, receivedResult, file: file, line: line)
                exp.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 2)
    }

    class URLProtocolStub: URLProtocol {
        nonisolated(unsafe) static var urlResponse: URLResponse?
        nonisolated(unsafe) static var data: Data?
        nonisolated(unsafe) static var error: Error?

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let error = URLProtocolStub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }

            if let data = URLProtocolStub.data {
                client?.urlProtocol(self, didLoad: data)
            }

            if let urlResponse = URLProtocolStub.urlResponse {
                client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
