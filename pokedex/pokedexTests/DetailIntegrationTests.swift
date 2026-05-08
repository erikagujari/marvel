//
//  DetailIntegrationTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 30/10/21.
//

import Combine
@testable import pokedex
import XCTest

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
        let exp = expectation(description: "Waiting to complete image")
        var cancellabes = Set<AnyCancellable>()

        sut.loadViewIfNeeded()

        imageResult
            .receive(on: DispatchQueue.main)
            .sink { _ in
                XCTAssertNil(sut.imageView.subviews.first(where: { $0 is Spinner }))
                exp.fulfill()
            } receiveValue: { _ in }.store(in: &cancellabes)

        wait(for: [exp], timeout: 1.0)
    }

    func test_loadView_updatesUIOnUseCaseCompletion() {
        let detail = anyPokemonDetail()
        let detailResult = Just(detail).setFailureType(to: APIError.self).eraseToAnyPublisher()
        let (sut, _) = makeSUT(detailResult: detailResult,
                               imageResult: Just(UIImage()).setFailureType(to: APIError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to complete pokemon detail")
        var cancellabes = Set<AnyCancellable>()

        sut.loadViewIfNeeded()

        detailResult
            .receive(on: DispatchQueue.main)
            .sink { _ in
                XCTAssertEqual(sut.titleLabel.text, detail.name)
                XCTAssertEqual(sut.descriptionLabel.text, detail.description)
                exp.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellabes)

        wait(for: [exp], timeout: 1.0)
    }

    func test_loadView_showsErrorOnUseCaseError() {
        let detailResult = Fail<PokemonDetail, APIError>(error: APIError.serviceError).eraseToAnyPublisher()
        let (viewController, router) = makeSUT(detailResult: detailResult,
                                               imageResult: Just(UIImage()).setFailureType(to: APIError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to complete pokemon detail")
        var cancellabes = Set<AnyCancellable>()

        viewController.loadViewIfNeeded()
        detailResult
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
                XCTAssertTrue(router.isDismissing)
                exp.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellabes)

        wait(for: [exp], timeout: 1.0)
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
