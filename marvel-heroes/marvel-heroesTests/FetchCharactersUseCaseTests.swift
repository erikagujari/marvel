//
//  FetchCharactersUseCaseTests.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 24/10/21.
//
import Combine
import XCTest
@testable import marvel_heroes

final class FetchCharacterUseCaseTests: XCTestCase {
    func test_executeFails_onRepositoryError() {
        let error = MarvelError.serviceError
        let sut = makeSUT(result: Fail<[MarvelCharacter], MarvelError>(error: error).eraseToAnyPublisher())
        
        expect(sut: sut, endsWithResult: .failure(error))
    }
    
    func test_executeFails_onRepositoryEmptyList() {
        let sut = makeSUT(result: Just<[MarvelCharacter]>([]).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        
        expect(sut: sut, endsWithResult: .failure(.serviceError))
    }
    
    func test_executeFinishes_onRepositoryNotEmptyList() {
        let characters = [MarvelCharacter(id: 0, name: "", description: "", modified: "", thumbnail: Thumbnail(path: "", fileExtension: ""))]
        let sut = makeSUT(result: Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        
        expect(sut: sut, endsWithResult: .finished)
    }
}

private extension FetchCharacterUseCaseTests {
    func makeSUT(result: AnyPublisher<[MarvelCharacter], MarvelError>) -> FetchCharacterUseCase {
        return FetchCharacterUseCaseProvider(repository: CharacterRepositoryStub(result: result))
    }
    
    func expect(sut: FetchCharacterUseCase, endsWithResult expectedResult: Subscribers.Completion<MarvelError>, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Waiting to complete execute")
        var cancellables = Set<AnyCancellable>()
        
        sut.execute(limit: 0, offset: 0)
            .sink { receivedResult in
                XCTAssertEqual(expectedResult, receivedResult, file: file, line: line)
                exp.fulfill()
            } receiveValue: { characters in
                XCTAssertFalse(characters.isEmpty)
            }
            .store(in: &cancellables)
        
        wait(for: [exp], timeout: 0.1)
    }
    
    struct CharacterRepositoryStub: CharacterRepository {
        private let result: AnyPublisher<[MarvelCharacter], MarvelError>
        
        init(result: AnyPublisher<[MarvelCharacter], MarvelError>) {
            self.result = result
        }
        
        func fetch(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError> {
            return result
        }
    }
}
