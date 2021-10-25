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
    
    func test_execeuteFails_onEmptyBundleDictionary() {
        let characters = anyMarvelCharacterList()
        let sut = makeSUT(result: Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: [:])
        
        expect(sut: sut, endsWithResult: .failure(.apiKeyError))
    }
    
    func test_executeFails_onBundleDictionaryWithoutKey() {
        let characters = anyMarvelCharacterList()
        let sut = makeSUT(result: Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: ["NOT_API_KEY": "any value"])
        
        expect(sut: sut, endsWithResult: .failure(.apiKeyError))
    }
    
    func test_executeFails_onBundleDictionaryWithoutApiPublicKeyStringType() {
        let characters = anyMarvelCharacterList()
        let sut = makeSUT(result: Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: ["API_PUBLIC_KEY": 1])
        
        expect(sut: sut, endsWithResult: .failure(.apiKeyError))
    }
    
    func test_executeFails_onBundleDictionaryWithoutApiPrivateKeyStringType() {
        let characters = anyMarvelCharacterList()
        let sut = makeSUT(result: Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: ["API_PUBLIC_KEY": "1",
                                       "API_PRIVATE_KEY": 1])
        
        expect(sut: sut, endsWithResult: .failure(.apiKeyError))
    }
    
    func test_executeFinishes_onRepositoryNotEmptyList_andValidBundleDictionary() {
        let characters = anyMarvelCharacterList()
        let sut = makeSUT(result: Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: ["API_PUBLIC_KEY": "1",
                                       "API_PRIVATE_KEY": "1"])

        expect(sut: sut, endsWithResult: .finished)
    }
}

private extension FetchCharacterUseCaseTests {
    func makeSUT(result: AnyPublisher<[MarvelCharacter], MarvelError>, dictionary: [String: Any]? = nil) -> FetchCharacterUseCase {
        return FetchCharacterUseCaseProvider(repository: CharacterRepositoryStub(result: result),
                                             bundle: TestBundle(dictionary: dictionary ?? anyValidBundleDictionary()))
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
        
        func fetch(parameters: CharacterService.ListParameters) -> AnyPublisher<[MarvelCharacter], MarvelError> {
            return result
        }
    }
    
    class TestBundle: Bundle {
        private let dictionary: [String: Any]
        
        init(dictionary: [String: Any]) {
            self.dictionary = dictionary
            
            super.init()
        }
        
        override func object(forInfoDictionaryKey key: String) -> Any? {
            return dictionary[key]
        }
    }
    
    func anyValidBundleDictionary() -> [String: Any] {
        return ["API_PUBLIC_KEY": "",
                "API_PRIVATE_KEY": ""]
    }
}
