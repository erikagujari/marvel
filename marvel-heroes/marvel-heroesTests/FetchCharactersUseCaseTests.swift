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
        let exp = expectation(description: "Waiting for execute to complete")
        var cancellables = Set<AnyCancellable>()
        sut.execute(limit: 0, offset: 1)
            .sink { result in
                switch result {
                case let .failure(receivedError):
                    XCTAssertEqual(error, receivedError)
                case .finished:
                    XCTFail("It should not finish")
                }
                exp.fulfill()
            } receiveValue: { _ in
                
            }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 0.1)
    }
    
    func test_executeFails_onRepositoryEmptyList() {
        let sut = makeSUT(result: Just<[MarvelCharacter]>([]).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting for execute to complete")
        var cancellables = Set<AnyCancellable>()
        sut.execute(limit: 0, offset: 1)
            .sink { result in
                switch result {
                case let .failure(receivedError):
                    XCTAssertEqual(.serviceError, receivedError)
                case .finished:
                    XCTFail("It should not finish")
                }
                exp.fulfill()
            } receiveValue: { _ in
                
            }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 0.1)
    }
    
    func test_executeFinishes_onRepositoryNotEmptyList() {
        let characters = [MarvelCharacter(id: 0, name: "", description: "", modified: "", thumbnail: Thumbnail(path: "", fileExtension: ""))]
        let sut = makeSUT(result: Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting for execute to complete")
        var cancellables = Set<AnyCancellable>()
        sut.execute(limit: 0, offset: 1)
            .sink { result in
                switch result {
                case .failure:
                    XCTFail("It should not finish on failure")
                case .finished: break
                }
                exp.fulfill()
            } receiveValue: { _ in
                
            }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 0.1)
    }
}

private extension FetchCharacterUseCaseTests {
    func makeSUT(result: AnyPublisher<[MarvelCharacter], MarvelError>) -> FetchCharacterUseCase {
        return FetchCharacterUseCaseProvider(repository: CharacterRepositoryStub(result: result))
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
