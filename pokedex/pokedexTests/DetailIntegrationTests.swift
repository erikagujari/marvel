//
//  DetailIntegrationTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 30/10/21.
//
@testable import pokedex
import SwiftUI
import XCTest

@MainActor
final class DetailIntegrationTests: XCTestCase {
    func test_loadView_updatesViewModelOnUseCaseSuccess() async {
        let detail = anyPokemonDetail()
        let setup = makeSUT(detailResult: .success(detail))
        _ = setup.window

        await waitFor { setup.viewModel.pokemon != nil }

        XCTAssertEqual(setup.viewModel.pokemon, detail)
    }

    func test_loadView_setsErrorAlertOnUseCaseError() async {
        let setup = makeSUT(detailResult: .failure(.serviceError))
        _ = setup.window

        await waitFor { setup.viewModel.errorAlert != nil }

        XCTAssertNotNil(setup.viewModel.errorAlert)
    }

    func test_loadView_settlesIsLoadingAfterFetch() async {
        let setup = makeSUT(detailResult: .success(anyPokemonDetail()))
        _ = setup.window

        await waitFor { setup.viewModel.pokemon != nil }

        XCTAssertFalse(setup.viewModel.isLoading)
    }
}

private extension DetailIntegrationTests {
    struct Setup {
        let window: UIWindow
        let viewModel: DetailViewModel
        let coordinator: AppCoordinator
    }

    func makeSUT(detailResult: Result<PokemonDetail, APIError>) -> Setup {
        let useCase = FetchPokemonDetailUseCaseStub(result: detailResult)
        let viewModel = DetailViewModel(id: 0, fetchUseCase: useCase)
        let imageLoader = ImageLoaderUseCaseStub(result: .success(UIImage()))
        let coordinator = AppCoordinator()
        let view = DetailView(viewModel: viewModel, coordinator: coordinator, imageLoader: imageLoader)
        let host = UIHostingController(rootView: view)
        trackForMemoryLeaks(instance: viewModel)
        trackForMemoryLeaks(instance: coordinator)
        trackForMemoryLeaks(instance: host)

        return Setup(window: mountInWindow(host), viewModel: viewModel, coordinator: coordinator)
    }

    struct FetchPokemonDetailUseCaseStub: FetchPokemonDetailUseCase {
        let result: Result<PokemonDetail, APIError>

        func execute(id: Int) async throws -> PokemonDetail {
            try result.get()
        }
    }
}
