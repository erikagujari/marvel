//
//  DetailIntegrationTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 30/10/21.
//

import Combine
@testable import pokedex
import XCTest

@MainActor
final class DetailIntegrationTests: XCTestCase {
    func test_loadView_showsSpinnerOnImageView() {
        let (sut, _) = makeSUT(detailResult: Just(anyPokemonDetail()).setFailureType(to: APIError.self).eraseToAnyPublisher(),
                               imageResult: Just(UIImage()).delay(for: 3, scheduler: RunLoop.main).setFailureType(to: APIError.self).eraseToAnyPublisher())

        sut.loadViewIfNeeded()

        XCTAssertNotNil(sut.imageView.subviews.first(where: { $0 is Spinner }))
    }

    func test_loadView_dismissesSpinnerOnImageViewWhenCompleted() {
        let imageResult = Just(UIImage()).setFailureType(to: APIError.self).eraseToAnyPublisher()
        let (sut, _) = makeSUT(detailResult: Just(anyPokemonDetail()).setFailureType(to: APIError.self).eraseToAnyPublisher(),
                               imageResult: imageResult)

        sut.loadViewIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNil(sut.imageView.subviews.first(where: { $0 is Spinner }))
    }

    func test_loadView_updatesUIOnUseCaseCompletion() {
        let detail = anyPokemonDetail()
        let detailResult = Just(detail).setFailureType(to: APIError.self).eraseToAnyPublisher()
        let (sut, _) = makeSUT(detailResult: detailResult,
                               imageResult: Just(UIImage()).setFailureType(to: APIError.self).eraseToAnyPublisher())

        sut.loadViewIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertEqual(sut.titleLabel.text, detail.name)
        XCTAssertEqual(sut.descriptionLabel.text, detail.description)
    }

    func test_loadView_showsErrorOnUseCaseError() {
        let detailResult = Fail<PokemonDetail, APIError>(error: APIError.serviceError).eraseToAnyPublisher()
        let (viewController, router) = makeSUT(detailResult: detailResult,
                                               imageResult: Just(UIImage()).setFailureType(to: APIError.self).eraseToAnyPublisher())

        viewController.loadViewIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertTrue(router.isDismissing)
    }
}

private extension DetailIntegrationTests {
    func makeSUT(detailResult: AnyPublisher<PokemonDetail, APIError>, imageResult: AnyPublisher<UIImage, APIError>) -> (DetailViewController, DetailRouterStub) {
        let router = DetailRouterStub()
        let useCase = FetchPokemonDetailUseCaseStub(result: detailResult)
        let imageLoader = ImageLoaderUseCaseStub(result: imageResult)
        let viewModel = DetailViewModel(id: 0, fetchUseCase: useCase, imageLoader: imageLoader)
        let viewController = DetailViewController(viewModel: viewModel, router: router)
        router.viewController = viewController
        trackForMemoryLeaks(instance: viewController)
        trackForMemoryLeaks(instance: viewModel)
        trackForMemoryLeaks(instance: router)

        return (viewController, router)
    }

    struct FetchPokemonDetailUseCaseStub: FetchPokemonDetailUseCase {
        let result: AnyPublisher<PokemonDetail, APIError>

        func execute(id: Int) -> AnyPublisher<PokemonDetail, APIError> {
            return result
        }
    }

    class DetailRouterStub: DetailRouterProtocol {
        weak var viewController: UIViewController?

        var isDismissing = false

        func showError(title: String, message: String) {
            isDismissing = true
        }
    }
}
