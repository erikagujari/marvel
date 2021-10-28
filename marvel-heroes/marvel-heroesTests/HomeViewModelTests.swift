//
//  HomeViewModelTests.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
import XCTest
@testable import marvel_heroes

final class HomeViewModelTests: XCTestCase {
    func test_fetchInitialCharacters_doesNotLoadCharactersOnUseCaseError() {
        let sut = makeSUT(fetchUseCaseResult: Fail<[MarvelCharacter], MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher())
        let initialValue = sut.characters.value
        
        sut.fetchInitialCharacters()
        let valueAfterLoad = sut.characters.value
        
        XCTAssertEqual(initialValue, valueAfterLoad)
    }
    
    func test_fetchInitialCharacters_loadsCharactersOnUseCaseSuccess() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyMarvelCharacterList()).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        let initialValue = sut.characters.value
        
        sut.fetchInitialCharacters()
        let valueAfterLoad = sut.characters.value
        
        XCTAssertNotEqual(initialValue, valueAfterLoad)
    }
    
    func test_cellModelCallsImageAction_onImageLoaderSuccess() {
        let image = UIImage(systemName: "star")!
        let sut = makeSUT(fetchUseCaseResult: Just(anyMarvelCharacterList()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Just(image).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to load image on cell model")
        
        sut.fetchInitialCharacters()
        _ = sut.cellModel(for: 0) { loadedImage in
            XCTAssertEqual(loadedImage, image)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_cellModelDoesNotCallImageAction_onImageLoaderFailure() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyMarvelCharacterList()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Fail(error: MarvelError.apiKeyError).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to load image on cell model")
        exp.isInverted = true
        
        sut.fetchInitialCharacters()
        _ = sut.cellModel(for: 0) { loadedImage in
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_willDisplayItemAtIndex_doesNotLoadMoreCharactersOnNotValidId() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyMarvelCharacterList(ids: [0, 1])).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Fail(error: MarvelError.apiKeyError).eraseToAnyPublisher())
        
        sut.fetchInitialCharacters()
        let itemsAfterInitialFetch = sut.characters.value
        sut.willDisplayItemAt(0)
        let itemsAfterDisplayItemAt = sut.characters.value
        
        XCTAssertEqual(itemsAfterInitialFetch, itemsAfterDisplayItemAt)
    }
    
    func test_willDisplayItemAtIndex_doesNotLoadMoreCharactersOnValidId_whenNextLoadIsFailure() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyMarvelCharacterList(ids: [0, 1])).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Fail(error: MarvelError.apiKeyError).eraseToAnyPublisher(),
                          nextLoadResult: Fail(error: MarvelError.serviceError).eraseToAnyPublisher())
        
        sut.fetchInitialCharacters()
        let itemsAfterInitialFetch = sut.characters.value
        sut.willDisplayItemAt(1)
        let itemsAfterDisplayItemAt = sut.characters.value
        
        XCTAssertEqual(itemsAfterInitialFetch, itemsAfterDisplayItemAt)
    }
    
    func test_willDisplayItemAtIndex_loadsMoreCharatersOnValidId_whenNextLoadIsSuccess() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyMarvelCharacterList(ids: [0, 1])).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Fail(error: MarvelError.apiKeyError).eraseToAnyPublisher(),
                          nextLoadResult: Just(anyMarvelCharacterList(ids: [2, 3, 4])).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        
        sut.fetchInitialCharacters()
        let itemsAfterInitialFetch = sut.characters.value
        sut.willDisplayItemAt(1)
        let itemsAfterDisplayItemAt = sut.characters.value
        
        XCTAssertNotEqual(itemsAfterInitialFetch, itemsAfterDisplayItemAt)
    }
}

private extension HomeViewModelTests {
    func makeSUT(fetchUseCaseResult: AnyPublisher<[MarvelCharacter], MarvelError>,
                 imageLoaderResult: AnyPublisher<UIImage, MarvelError> = Just(UIImage()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                 nextLoadResult: AnyPublisher<[MarvelCharacter], MarvelError> = Just(anyMarvelCharacterList(ids: [3,4,5])).setFailureType(to: MarvelError.self).eraseToAnyPublisher()) -> HomeViewModel {
        let fetchUseCase = FetchCharacterUseCaseStub(firstLoadResult: fetchUseCaseResult, nextLoadResult: nextLoadResult)
        return HomeViewModelProvider(fetchCharactersUseCase: fetchUseCase,
                                     limitRequest: 20,
                                     imageLoader: ImageLoaderUseCaseStub(result: imageLoaderResult))
    }
}
