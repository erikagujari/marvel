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

    func test_willDisplayItemAtIndex_doesNotLoadMoreCharactersOnNotValidId() async {
        let sut = makeSUT(fetchUseCaseResult: .success(anyPokemonList(ids: [0, 1])))

        await sut.fetchInitialCharacters()
        let itemsAfterInitialFetch = sut.characters
        await sut.willDisplayItemAt(0)

        XCTAssertEqual(itemsAfterInitialFetch, sut.characters)
    }

    func test_willDisplayItemAtIndex_doesNotLoadMoreCharactersOnValidId_whenNextLoadIsFailure() async {
        let sut = makeSUT(fetchUseCaseResult: .success(anyPokemonList(ids: [0, 1])),
                          nextLoadResult: .failure(.serviceError))

        await sut.fetchInitialCharacters()
        let itemsAfterInitialFetch = sut.characters
        await sut.willDisplayItemAt(1)

        XCTAssertEqual(itemsAfterInitialFetch, sut.characters)
    }

    func test_willDisplayItemAtIndex_loadsMoreCharatersOnValidId_whenNextLoadIsSuccess() async {
        let sut = makeSUT(fetchUseCaseResult: .success(anyPokemonList(ids: [0, 1])),
                          nextLoadResult: .success(anyPokemonList(ids: [2, 3, 4])))

        await sut.fetchInitialCharacters()
        let itemsAfterInitialFetch = sut.characters
        await sut.willDisplayItemAt(1)

        XCTAssertNotEqual(itemsAfterInitialFetch, sut.characters)
    }

    func test_refresh_replacesCharactersWithReloadedFirstPage() async {
        let firstPage = anyPokemonList(ids: [0, 1])
        let refreshedPage = anyPokemonList(ids: [99])
        let sut = makeSUT(fetchUseCaseResult: .success(firstPage),
                          nextLoadResult: .success(refreshedPage))

        await sut.fetchInitialCharacters()
        XCTAssertEqual(sut.characters, firstPage)

        await sut.refresh()

        XCTAssertEqual(sut.characters, refreshedPage)
    }

    func test_concurrentFetchInitialCharacters_doesNotDoubleAppend() async {
        let firstPage = anyPokemonList(ids: [0, 1])
        let fetchUseCase = FetchPokemonUseCaseStub(
            firstLoadResult: .success(firstPage),
            delay: .milliseconds(50),
            nextLoadResult: .success(anyPokemonList(ids: [2, 3, 4]))
        )
        let sut = HomeViewModel(fetchPokemonUseCase: fetchUseCase, limitRequest: 20)

        async let first: Void = sut.fetchInitialCharacters()
        async let second: Void = sut.refresh()
        _ = await (first, second)

        XCTAssertEqual(sut.characters, firstPage)
    }
}

private extension HomeViewModelTests {
    func makeSUT(fetchUseCaseResult: Result<[Pokemon], APIError>,
                 nextLoadResult: Result<[Pokemon], APIError> = .success(anyPokemonList(ids: [3, 4, 5]))) -> HomeViewModelProtocol {
        let fetchUseCase = FetchPokemonUseCaseStub(firstLoadResult: fetchUseCaseResult, nextLoadResult: nextLoadResult)
        return HomeViewModel(fetchPokemonUseCase: fetchUseCase, limitRequest: 20)
    }
}
