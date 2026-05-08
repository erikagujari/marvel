//
//  FetchPokemonDetailUseCaseTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 30/10/21.
//
@testable import pokedex
import XCTest

final class FetchPokemonDetailUseCaseTests: XCTestCase {
    func test_executeFails_onRepositoryError() async {
        let expected = APIError.serviceError
        let sut = makeSUT(result: .failure(expected))

        do {
            _ = try await sut.execute(id: 0)
            XCTFail("Expected error but got success")
        } catch let error as APIError {
            XCTAssertEqual(error, expected)
        } catch {
            XCTFail("Expected APIError but got \(error)")
        }
    }

    func test_executeFinishes_onRepositorySuccess() async throws {
        let detail = anyPokemonDetail()
        let sut = makeSUT(result: .success(detail))

        let result = try await sut.execute(id: 0)
        XCTAssertEqual(result, detail)
    }
}

private extension FetchPokemonDetailUseCaseTests {
    func makeSUT(result: Result<PokemonDetail, APIError>) -> FetchPokemonDetailUseCase {
        let repository = PokemonRepositoryStub(listResult: .failure(.serviceError), detailResult: result)
        return FetchPokemonDetailUseCaseProvider(repository: repository)
    }
}
