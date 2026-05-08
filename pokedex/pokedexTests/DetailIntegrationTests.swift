//
//  DetailIntegrationTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 30/10/21.
//
@testable import pokedex
import XCTest

@MainActor
final class DetailIntegrationTests: XCTestCase {
    func test_loadView_showsSpinnerOnImageView() async {
        let (sut, _) = makeSUT(detailResult: .success(anyPokemonDetail()),
                               imageResult: .success(UIImage()),
                               imageDelay: .seconds(3))

        sut.loadViewIfNeeded()

        XCTAssertNotNil(sut.imageView.subviews.first(where: { $0 is Spinner }))
    }

    func test_loadView_dismissesSpinnerOnImageViewWhenCompleted() async {
        let (sut, _) = makeSUT(detailResult: .success(anyPokemonDetail()),
                               imageResult: .success(UIImage()))

        sut.loadViewIfNeeded()
        await waitFor { !sut.imageView.subviews.contains(where: { $0 is Spinner }) }

        XCTAssertNil(sut.imageView.subviews.first(where: { $0 is Spinner }))
    }

    func test_loadView_updatesUIOnUseCaseCompletion() async {
        let detail = anyPokemonDetail()
        let (sut, _) = makeSUT(detailResult: .success(detail),
                               imageResult: .success(UIImage()))

        sut.loadViewIfNeeded()
        await waitFor { sut.titleLabel.text == detail.name }

        XCTAssertEqual(sut.titleLabel.text, detail.name)
        XCTAssertEqual(sut.descriptionLabel.text, detail.description)
    }

    func test_loadView_showsErrorOnUseCaseError() async {
        let (viewController, router) = makeSUT(detailResult: .failure(.serviceError),
                                               imageResult: .success(UIImage()))

        viewController.loadViewIfNeeded()
        await waitFor { router.isDismissing }

        XCTAssertTrue(router.isDismissing)
    }
}

private extension DetailIntegrationTests {
    func makeSUT(detailResult: Result<PokemonDetail, APIError>,
                 imageResult: Result<UIImage, APIError>,
                 imageDelay: Duration? = nil) -> (DetailViewController, DetailRouterStub) {
        let router = DetailRouterStub()
        let useCase = FetchPokemonDetailUseCaseStub(result: detailResult)
        let imageLoader = ImageLoaderUseCaseStub(result: imageResult, delay: imageDelay)
        let viewModel = DetailViewModel(id: 0, fetchUseCase: useCase, imageLoader: imageLoader)
        let viewController = DetailViewController(viewModel: viewModel, router: router)
        router.viewController = viewController
        trackForMemoryLeaks(instance: viewController)
        trackForMemoryLeaks(instance: viewModel)
        trackForMemoryLeaks(instance: router)

        return (viewController, router)
    }

    struct FetchPokemonDetailUseCaseStub: FetchPokemonDetailUseCase {
        let result: Result<PokemonDetail, APIError>

        func execute(id: Int) async throws -> PokemonDetail {
            try result.get()
        }
    }

    @MainActor
    final class DetailRouterStub: DetailRouterProtocol {
        weak var viewController: UIViewController?

        var isDismissing = false

        func showError(title: String, message: String) {
            isDismissing = true
        }
    }
}
