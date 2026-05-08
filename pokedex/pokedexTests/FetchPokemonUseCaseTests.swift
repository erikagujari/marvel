//
//  FetchPokemonUseCaseTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 24/10/21.
//
@testable import pokedex
import XCTest

final class FetchPokemonUseCaseTests: XCTestCase {
    func test_executeFails_onRepositoryError() async {
        let expected = APIError.serviceError
        let sut = makeSUT(result: .failure(expected))

        await assertThrows(sut: sut, expected: expected)
    }

    func test_executeFails_onRepositoryEmptyList() async {
        let sut = makeSUT(result: .success([]))

        await assertThrows(sut: sut, expected: .serviceError)
    }

    func test_executeFinishes_onRepositoryNotEmptyList() async throws {
        let pokemon = anyPokemonList()
        let sut = makeSUT(result: .success(pokemon))

        let result = try await sut.execute(limit: 0, offset: 0)
        XCTAssertEqual(result, pokemon)
    }
}

private extension FetchPokemonUseCaseTests {
    func makeSUT(result: Result<[Pokemon], APIError>) -> FetchPokemonUseCase {
        let repository = PokemonRepositoryStub(listResult: result, detailResult: .failure(.serviceError))
        return FetchPokemonUseCaseProvider(repository: repository)
    }

    func assertThrows(sut: FetchPokemonUseCase, expected: APIError, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await sut.execute(limit: 0, offset: 0)
            XCTFail("Expected error but got success", file: file, line: line)
        } catch let error as APIError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected APIError but got \(error)", file: file, line: line)
        }
    }
}
