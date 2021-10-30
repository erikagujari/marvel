//
//  FetchCharacterDetailUseCaseTests.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 30/10/21.
//

import Combine
import XCTest
@testable import marvel_heroes

final class FetchCharacterDetailUseCaseTests: XCTestCase {
    func test_executeFails_onRepositoryError() {
        let error = MarvelError.serviceError
        let sut = makeSUT(result: Fail(error: error).eraseToAnyPublisher())
        
        expect(sut: sut, endsWithResult: .failure(error))
    }
    
    func test_execeuteFails_onEmptyBundleDictionary() {
        let sut = makeSUT(result: Just(anyMarvelCharacterDetailResponse()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: [:])
        
        expect(sut: sut, endsWithResult: .failure(.apiKeyError))
    }
    
    func test_executeFails_onBundleDictionaryWithoutKey() {
        let sut = makeSUT(result: Just(anyMarvelCharacterDetailResponse()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: ["NOT_API_KEY": "any value"])
        
        expect(sut: sut, endsWithResult: .failure(.apiKeyError))
    }
    
    func test_executeFails_onBundleDictionaryWithoutApiPublicKeyStringType() {
        let sut = makeSUT(result: Just(anyMarvelCharacterDetailResponse()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: ["API_PUBLIC_KEY": 1])
        
        expect(sut: sut, endsWithResult: .failure(.apiKeyError))
    }
    
    func test_executeFails_onBundleDictionaryWithoutApiPrivateKeyStringType() {
        let sut = makeSUT(result: Just(anyMarvelCharacterDetailResponse()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: ["API_PUBLIC_KEY": "1",
                                       "API_PRIVATE_KEY": 1])
        
        expect(sut: sut, endsWithResult: .failure(.apiKeyError))
    }
    
    func test_executeFinishes_onRepositoryNotEmptyList_andValidBundleDictionary() {
        let sut = makeSUT(result: Just(anyMarvelCharacterDetailResponse()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          dictionary: ["API_PUBLIC_KEY": "1",
                                       "API_PRIVATE_KEY": "1"])

        expect(sut: sut, endsWithResult: .finished)
    }
}

private extension FetchCharacterDetailUseCaseTests {
    func makeSUT(result: AnyPublisher<CharacterDetailResponse, MarvelError>, dictionary: [String: Any]? = nil) -> FetchCharacterDetailUseCase {
        let repository = CharacterRepositoryStub(listResult: Fail(error: MarvelError.serviceError).eraseToAnyPublisher(),
                                                 detailResult: result)
        let authorization = AuthorizedUseCaseProvider(bundle: TestBundle(dictionary: dictionary ?? anyValidBundleDictionary()))
        
        return FetchCharacterDetailUseCaseProvider(repository: repository, authorization: authorization)
    }
    
    func expect(sut: FetchCharacterDetailUseCase, endsWithResult expectedResult: Subscribers.Completion<MarvelError>, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Waiting to complete execute")
        var cancellables = Set<AnyCancellable>()
        
        sut.execute(id: 0)
            .sink { receivedResult in
                XCTAssertEqual(expectedResult, receivedResult, file: file, line: line)
                exp.fulfill()
            } receiveValue: { characters in }
            .store(in: &cancellables)
        
        wait(for: [exp], timeout: 0.1)
    }
    
    func anyMarvelCharacterDetailResponse() -> CharacterDetailResponse {
        return CharacterDetailResponse(data: CharacterDetailResponseData(results: anyMarvelCharacterList()))
    }
}
