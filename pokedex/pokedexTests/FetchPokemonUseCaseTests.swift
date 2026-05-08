//
//  FetchPokemonUseCaseTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 24/10/21.
//
import Combine
@testable import pokedex
import XCTest

final class FetchPokemonUseCaseTests: XCTestCase {
    func test_executeFails_onRepositoryError() {
        let error = APIError.serviceError
        let sut = makeSUT(result: Fail<[Pokemon], APIError>(error: error).eraseToAnyPublisher())

        expect(sut: sut, endsWithResult: .failure(error))
    }

    func test_executeFails_onRepositoryEmptyList() {
        let sut = makeSUT(result: Just<[Pokemon]>([]).setFailureType(to: APIError.self).eraseToAnyPublisher())

        expect(sut: sut, endsWithResult: .failure(.serviceError))
    }

    func test_executeFinishes_onRepositoryNotEmptyList() {
        let pokemon = anyPokemonList()
        let sut = makeSUT(result: Just<[Pokemon]>(pokemon).setFailureType(to: APIError.self).eraseToAnyPublisher())

        expect(sut: sut, endsWithResult: .finished)
    }
}

private extension FetchPokemonUseCaseTests {
    func makeSUT(result: AnyPublisher<[Pokemon], APIError>) -> FetchPokemonUseCase {
        let repository = PokemonRepositoryStub(listResult: result,
                                               detailResult: Fail(error: APIError.serviceError).eraseToAnyPublisher())
        return FetchPokemonUseCaseProvider(repository: repository)
    }

    func expect(sut: FetchPokemonUseCase, endsWithResult expectedResult: Subscribers.Completion<APIError>, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Waiting to complete execute")
        var cancellables = Set<AnyCancellable>()

        sut.execute(limit: 0, offset: 0)
            .sink { receivedResult in
                XCTAssertEqual(expectedResult, receivedResult, file: file, line: line)
                exp.fulfill()
            } receiveValue: { pokemon in
                XCTAssertFalse(pokemon.isEmpty, file: file, line: line)
            }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 0.1)
    }
}
