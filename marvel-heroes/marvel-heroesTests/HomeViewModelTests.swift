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
}

private extension HomeViewModelTests {
    func makeSUT(fetchUseCaseResult: AnyPublisher<[MarvelCharacter], MarvelError>,
                 imageLoaderResult: AnyPublisher<UIImage, MarvelError> = Just(UIImage()).setFailureType(to: MarvelError.self).eraseToAnyPublisher()) -> HomeViewModel {
        return HomeViewModelProvider(fetchCharactersUseCase: FetchCharacterUseCaseStub(result: fetchUseCaseResult),
                                     limitRequest: 20,
                                     imageLoader: ImageLoaderUseCaseStub(result: imageLoaderResult))
    }
}

extension MarvelCharacterModel: Equatable {
    public static func == (lhs: MarvelCharacterModel, rhs: MarvelCharacterModel) -> Bool {
        return lhs.id == rhs.id
    }
}
