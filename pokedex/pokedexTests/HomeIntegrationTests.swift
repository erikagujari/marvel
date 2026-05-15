//
//  HomeIntegrationTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 26/10/21.
//
@testable import pokedex
import SwiftUI
import XCTest

@MainActor
final class HomeIntegrationTests: XCTestCase {
    func test_loadView_doesNotLoadCharactersOnViewModelError() async {
        let (window, viewModel) = makeSUT(initialResult: .failure(.serviceError))
        _ = window

        await waitFor { viewModel.errorAlert != nil || (!viewModel.isLoading && !viewModel.characters.isEmpty) }

        XCTAssertEqual(viewModel.characters.count, 0)
    }

    func test_loadView_loadsCharactersOnViewModelSuccess() async {
        let list = anyPokemonList()
        let (window, viewModel) = makeSUT(initialResult: .success(list))
        _ = window

        await waitFor { viewModel.characters.count == list.count }

        XCTAssertEqual(viewModel.characters.count, list.count)
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_loadView_setsIsLoadingDuringDelay() async {
        let list = anyPokemonList()
        let (window, viewModel) = makeSUT(initialResult: .success(list), delay: .milliseconds(100))
        _ = window

        await waitFor { viewModel.isLoading }
        XCTAssertTrue(viewModel.isLoading)

        await waitFor(timeout: .seconds(2)) { viewModel.characters.count == list.count }
    }

    func test_loadView_setsErrorAlertOnViewModelError() async {
        let (window, viewModel) = makeSUT(initialResult: .failure(.serviceError))
        _ = window

        await waitFor { viewModel.errorAlert != nil }

        XCTAssertNotNil(viewModel.errorAlert)
    }
}

private extension HomeIntegrationTests {
    func makeSUT(initialResult: Result<[Pokemon], APIError>,
                 delay: Duration? = nil) -> (UIWindow, HomeViewModel) {
        let fetchUseCase = FetchPokemonUseCaseStub(firstLoadResult: initialResult, delay: delay)
        let viewModel = HomeViewModel(fetchPokemonUseCase: fetchUseCase, limitRequest: 10)
        let imageLoader = ImageLoaderUseCaseStub(result: .success(UIImage()))
        let view = HomeView(viewModel: viewModel, imageLoader: imageLoader)
        let host = UIHostingController(rootView: view)
        trackForMemoryLeaks(instance: viewModel)
        trackForMemoryLeaks(instance: host)

        return (mountInWindow(host), viewModel)
    }
}
