//
//  PokemonRepositoryTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 23/10/21.
//
@testable import pokedex
import XCTest

final class PokemonRepositoryTests: XCTestCase {
    func test_fetchReturnsServiceError_onNilHTTPResponse() async {
        let sut = makeSUT(data: nil, urlResponse: nil, error: nil)

        await expectFetchListThrows(sut: sut, expected: .serviceError)
        await expectFetchDetailThrows(sut: sut, expected: .serviceError)
    }

    func test_fetchReturnsServiceError_onNotHTTPURLResponse() async {
        let sut = makeSUT(data: nil, urlResponse: URLResponse(), error: nil)

        await expectFetchListThrows(sut: sut, expected: .serviceError)
        await expectFetchDetailThrows(sut: sut, expected: .serviceError)
    }

    func test_fetchReturnsServiceError_on199StatusCode() async {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 199,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: nil, urlResponse: urlResponse, error: nil)

        await expectFetchListThrows(sut: sut, expected: .serviceError)
        await expectFetchDetailThrows(sut: sut, expected: .serviceError)
    }

    func test_fetchReturnsServiceError_on300StatusCode() async {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 300,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: nil, urlResponse: urlResponse, error: nil)

        await expectFetchListThrows(sut: sut, expected: .serviceError)
        await expectFetchDetailThrows(sut: sut, expected: .serviceError)
    }

    func test_fetchReturnsMappingError_onNilData() async {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: nil, urlResponse: urlResponse, error: nil)

        await expectFetchListThrows(sut: sut, expected: .mappingError)
        await expectFetchDetailThrows(sut: sut, expected: .mappingError)
    }

    func test_fetchReturnsMappingError_onEmptyData() async {
        let data = Data()
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: data, urlResponse: urlResponse, error: nil)

        await expectFetchListThrows(sut: sut, expected: .mappingError)
        await expectFetchDetailThrows(sut: sut, expected: .mappingError)
    }

    func test_fetchReturnsMappingError_onInvalidData() async {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: anyInvalidJSON(), urlResponse: urlResponse, error: nil)

        await expectFetchListThrows(sut: sut, expected: .mappingError)
        await expectFetchDetailThrows(sut: sut, expected: .mappingError)
    }

    func test_fetchListReturnsPokemon_onValidListData() async throws {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: anyValidPokemonListJSON(), urlResponse: urlResponse, error: nil)

        let pokemon = try await sut.fetch(offset: 0, limit: 0)
        XCTAssertFalse(pokemon.isEmpty)
    }

    func test_fetchReturnsServiceError_onAnyError() async {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: anyValidPokemonListJSON(), urlResponse: urlResponse, error: APIError.mappingError)

        await expectFetchListThrows(sut: sut, expected: .serviceError)
        await expectFetchDetailThrows(sut: sut, expected: .serviceError)
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

    func expectFetchListThrows(sut: PokemonRepository, expected: APIError, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await sut.fetch(offset: 0, limit: 0)
            XCTFail("Expected error \(expected) but got success", file: file, line: line)
        } catch let error as APIError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected APIError but got \(error)", file: file, line: line)
        }
    }

    func expectFetchDetailThrows(sut: PokemonRepository, expected: APIError, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await sut.fetchDetail(id: 0)
            XCTFail("Expected error \(expected) but got success", file: file, line: line)
        } catch let error as APIError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected APIError but got \(error)", file: file, line: line)
        }
    }

    final class URLProtocolStub: URLProtocol {
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
                return
            }

            // URLSession's async `data(for:)` requires a response before completion;
            // otherwise it traps. Emit one (real if provided, placeholder otherwise) so
            // the "nil HTTP response" tests can exercise the non-HTTPURLResponse code path.
            let response = URLProtocolStub.urlResponse ?? URLResponse()
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

            if let data = URLProtocolStub.data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }
}
