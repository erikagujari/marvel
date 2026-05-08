//
//  FetchPokemonDetailUseCaseTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 30/10/21.
//

import Combine
@testable import pokedex
import XCTest

final class FetchPokemonDetailUseCaseTests: XCTestCase {
    func test_executeFails_onRepositoryError() {
        let error = APIError.serviceError
        let sut = makeSUT(result: Fail(error: error).eraseToAnyPublisher())

        expect(sut: sut, endsWithResult: .failure(error))
    }

    func test_executeFinishes_onRepositorySuccess() {
        let sut = makeSUT(result: Just(anyPokemonDetail()).setFailureType(to: APIError.self).eraseToAnyPublisher())

        expect(sut: sut, endsWithResult: .finished)
    }
}

private extension FetchPokemonDetailUseCaseTests {
    func makeSUT(result: AnyPublisher<PokemonDetail, APIError>) -> FetchPokemonDetailUseCase {
        let repository = PokemonRepositoryStub(listResult: Fail(error: APIError.serviceError).eraseToAnyPublisher(),
                                               detailResult: result)
        return FetchPokemonDetailUseCaseProvider(repository: repository)
    }

    func expect(sut: FetchPokemonDetailUseCase, endsWithResult expectedResult: Subscribers.Completion<APIError>, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Waiting to complete execute")
        var cancellables = Set<AnyCancellable>()

        sut.execute(id: 0)
            .sink { receivedResult in
                XCTAssertEqual(expectedResult, receivedResult, file: file, line: line)
                exp.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 0.1)
    }
}
