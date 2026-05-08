//
//  HomeViewModelTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
@testable import pokedex
import XCTest

@MainActor
final class HomeViewModelTests: XCTestCase {
    func test_fetchInitialCharacters_doesNotLoadCharactersOnUseCaseError() {
        let sut = makeSUT(fetchUseCaseResult: Fail<[Pokemon], APIError>(error: APIError.serviceError).eraseToAnyPublisher())
        let initialValue = sut.characters.value

        sut.fetchInitialCharacters()
        let valueAfterLoad = sut.characters.value

        XCTAssertEqual(initialValue, valueAfterLoad)
    }

    func test_fetchInitialCharacters_loadsCharactersOnUseCaseSuccess() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyPokemonList()).setFailureType(to: APIError.self).eraseToAnyPublisher())
        let initialValue = sut.characters.value

        sut.fetchInitialCharacters()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        let valueAfterLoad = sut.characters.value

        XCTAssertNotEqual(initialValue, valueAfterLoad)
    }

    func test_cellModelCallsImageAction_onImageLoaderSuccess() {
        let image = UIImage(systemName: "star")!
        let sut = makeSUT(fetchUseCaseResult: Just(anyPokemonList()).setFailureType(to: APIError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Just(image).setFailureType(to: APIError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to load image on cell model")

        sut.fetchInitialCharacters()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        _ = sut.cellModel(for: 0) { loadedImage in
            XCTAssertEqual(loadedImage, image)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_cellModelCallsImageActionWithWifiImage_onImageLoaderFailure() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyPokemonList()).setFailureType(to: APIError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Fail(error: APIError.serviceError).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to load image on cell model")

        sut.fetchInitialCharacters()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        _ = sut.cellModel(for: 0) { loadedImage in
            XCTAssertEqual(loadedImage.pngData(), UIImage(named: "wifi")?.pngData())
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_willDisplayItemAtIndex_doesNotLoadMoreCharactersOnNotValidId() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyPokemonList(ids: [0, 1])).setFailureType(to: APIError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Fail(error: APIError.serviceError).eraseToAnyPublisher())

        sut.fetchInitialCharacters()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        let itemsAfterInitialFetch = sut.characters.value
        sut.willDisplayItemAt(0)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        let itemsAfterDisplayItemAt = sut.characters.value

        XCTAssertEqual(itemsAfterInitialFetch, itemsAfterDisplayItemAt)
    }

    func test_willDisplayItemAtIndex_doesNotLoadMoreCharactersOnValidId_whenNextLoadIsFailure() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyPokemonList(ids: [0, 1])).setFailureType(to: APIError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Fail(error: APIError.serviceError).eraseToAnyPublisher(),
                          nextLoadResult: Fail(error: APIError.serviceError).eraseToAnyPublisher())

        sut.fetchInitialCharacters()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        let itemsAfterInitialFetch = sut.characters.value
        sut.willDisplayItemAt(1)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        let itemsAfterDisplayItemAt = sut.characters.value

        XCTAssertEqual(itemsAfterInitialFetch, itemsAfterDisplayItemAt)
    }

    func test_willDisplayItemAtIndex_loadsMoreCharatersOnValidId_whenNextLoadIsSuccess() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyPokemonList(ids: [0, 1])).setFailureType(to: APIError.self).eraseToAnyPublisher(),
                          imageLoaderResult: Fail(error: APIError.serviceError).eraseToAnyPublisher(),
                          nextLoadResult: Just(anyPokemonList(ids: [2, 3, 4])).setFailureType(to: APIError.self).eraseToAnyPublisher())

        sut.fetchInitialCharacters()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        let itemsAfterInitialFetch = sut.characters.value
        sut.willDisplayItemAt(1)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        let itemsAfterDisplayItemAt = sut.characters.value

        XCTAssertNotEqual(itemsAfterInitialFetch, itemsAfterDisplayItemAt)
    }
}

private extension HomeViewModelTests {
    func makeSUT(fetchUseCaseResult: AnyPublisher<[Pokemon], APIError>,
                 imageLoaderResult: AnyPublisher<UIImage, APIError> = Just(UIImage()).setFailureType(to: APIError.self).eraseToAnyPublisher(),
                 nextLoadResult: AnyPublisher<[Pokemon], APIError> = Just(anyPokemonList(ids: [3, 4, 5])).setFailureType(to: APIError.self).eraseToAnyPublisher()) -> HomeViewModelProtocol {
        let fetchUseCase = FetchPokemonUseCaseStub(firstLoadResult: fetchUseCaseResult, nextLoadResult: nextLoadResult)
        return HomeViewModel(fetchPokemonUseCase: fetchUseCase,
                             limitRequest: 20,
                             imageLoader: ImageLoaderUseCaseStub(result: imageLoaderResult))
    }
}
