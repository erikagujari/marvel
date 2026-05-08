//
//  HomeViewModelTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 25/10/21.
//
@testable import pokedex
import XCTest

@MainActor
final class HomeViewModelTests: XCTestCase {
    func test_fetchInitialCharacters_doesNotLoadCharactersOnUseCaseError() async {
        let sut = makeSUT(fetchUseCaseResult: .failure(.serviceError))
        let initialValue = sut.characters

        await sut.fetchInitialCharacters()

        XCTAssertEqual(initialValue, sut.characters)
    }

    func test_fetchInitialCharacters_loadsCharactersOnUseCaseSuccess() async {
        let sut = makeSUT(fetchUseCaseResult: .success(anyPokemonList()))
        let initialValue = sut.characters

        await sut.fetchInitialCharacters()

        XCTAssertNotEqual(initialValue, sut.characters)
    }

    func test_cellModelCallsImageAction_onImageLoaderSuccess() async {
        let image = UIImage(systemName: "star")!
        let sut = makeSUT(fetchUseCaseResult: .success(anyPokemonList()),
                          imageLoaderResult: .success(image))

        await sut.fetchInitialCharacters()
        let loadedImage = await captureImage(from: sut, at: 0)

        XCTAssertEqual(loadedImage, image)
    }

    func test_cellModelCallsImageActionWithWifiImage_onImageLoaderFailure() async {
        let sut = makeSUT(fetchUseCaseResult: .success(anyPokemonList()),
                          imageLoaderResult: .failure(.serviceError))

        await sut.fetchInitialCharacters()
        let loadedImage = await captureImage(from: sut, at: 0)

        XCTAssertEqual(loadedImage.pngData(), UIImage(named: "wifi")?.pngData())
    }

    func test_willDisplayItemAtIndex_doesNotLoadMoreCharactersOnNotValidId() async {
        let sut = makeSUT(fetchUseCaseResult: .success(anyPokemonList(ids: [0, 1])),
                          imageLoaderResult: .failure(.serviceError))

        await sut.fetchInitialCharacters()
        let itemsAfterInitialFetch = sut.characters
        await sut.willDisplayItemAt(0)

        XCTAssertEqual(itemsAfterInitialFetch, sut.characters)
    }

    func test_willDisplayItemAtIndex_doesNotLoadMoreCharactersOnValidId_whenNextLoadIsFailure() async {
        let sut = makeSUT(fetchUseCaseResult: .success(anyPokemonList(ids: [0, 1])),
                          imageLoaderResult: .failure(.serviceError),
                          nextLoadResult: .failure(.serviceError))

        await sut.fetchInitialCharacters()
        let itemsAfterInitialFetch = sut.characters
        await sut.willDisplayItemAt(1)

        XCTAssertEqual(itemsAfterInitialFetch, sut.characters)
    }

    func test_willDisplayItemAtIndex_loadsMoreCharatersOnValidId_whenNextLoadIsSuccess() async {
        let sut = makeSUT(fetchUseCaseResult: .success(anyPokemonList(ids: [0, 1])),
                          imageLoaderResult: .failure(.serviceError),
                          nextLoadResult: .success(anyPokemonList(ids: [2, 3, 4])))

        await sut.fetchInitialCharacters()
        let itemsAfterInitialFetch = sut.characters
        await sut.willDisplayItemAt(1)

        XCTAssertNotEqual(itemsAfterInitialFetch, sut.characters)
    }
}

private extension HomeViewModelTests {
    func makeSUT(fetchUseCaseResult: Result<[Pokemon], APIError>,
                 imageLoaderResult: Result<UIImage, APIError> = .success(UIImage()),
                 nextLoadResult: Result<[Pokemon], APIError> = .success(anyPokemonList(ids: [3, 4, 5]))) -> HomeViewModelProtocol {
        let fetchUseCase = FetchPokemonUseCaseStub(firstLoadResult: fetchUseCaseResult, nextLoadResult: nextLoadResult)
        return HomeViewModel(fetchPokemonUseCase: fetchUseCase,
                             limitRequest: 20,
                             imageLoader: ImageLoaderUseCaseStub(result: imageLoaderResult))
    }

    func captureImage(from sut: HomeViewModelProtocol, at index: Int) async -> UIImage {
        await withCheckedContinuation { (cont: CheckedContinuation<UIImage, Never>) in
            _ = sut.cellModel(for: index) { cont.resume(returning: $0) }
        }
    }
}
