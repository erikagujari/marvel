//
//  HomeIntegrationTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 26/10/21.
//
@testable import pokedex
import XCTest

@MainActor
final class HomeIntegrationTests: XCTestCase {
    func test_loadView_doesNotUpdateTableViewOnViewModelError() async {
        let (sut, _) = makeSUT(initialResult: .failure(.serviceError))

        sut.loadViewIfNeeded()
        await waitFor { sut.tableView(sut.tableView, numberOfRowsInSection: 0) > 0 || !self.isStillLoading(sut) }

        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: 0), 0)
    }

    func test_loadView_updatesTableViewOnViewModelSuccess_andDoesNotShowSpinner() async {
        let list = anyPokemonList()
        let (sut, _) = makeSUT(initialResult: .success(list))

        sut.loadViewIfNeeded()
        await waitFor { sut.tableView(sut.tableView, numberOfRowsInSection: 0) == list.count }

        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: 0), list.count)
        XCTAssertNil(sut.view.subviews.first(where: { $0 is Spinner }))
    }

    func test_loadView_showsSpinnerOnDelay() async {
        let list = anyPokemonList()
        let (sut, _) = makeSUT(initialResult: .success(list), delay: .milliseconds(100))
        sut.loadViewIfNeeded()
        await waitFor { sut.view.subviews.contains(where: { $0 is Spinner }) }
        XCTAssertNotNil(sut.view.subviews.first(where: { $0 is Spinner }))

        // Wait for the in-flight load to settle so the in-flight call frame releases the VM
        // before tearDown's leak check runs.
        await waitFor(timeout: .seconds(2)) { sut.tableView(sut.tableView, numberOfRowsInSection: 0) == list.count }
    }

    func test_loadView_showsErrorOnViewModelError() async {
        let (sut, router) = makeSUT(initialResult: .failure(.serviceError))

        sut.loadViewIfNeeded()
        await waitFor { router.didShowError }

        XCTAssertTrue(router.didShowError)
    }

    func test_selectRow_showsDetail() async {
        let list = anyPokemonList()
        let (sut, router) = makeSUT(initialResult: .success(list))

        sut.loadViewIfNeeded()
        await waitFor { sut.tableView(sut.tableView, numberOfRowsInSection: 0) == list.count }
        sut.tableView.delegate?.tableView?(sut.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))

        XCTAssertTrue(router.didShowDetail)
    }
}

private extension HomeIntegrationTests {
    func makeSUT(initialResult: Result<[Pokemon], APIError>, delay: Duration? = nil) -> (HomeViewController, HomeRouterSpy) {
        let fetchUseCase = FetchPokemonUseCaseStub(firstLoadResult: initialResult, delay: delay)
        let viewModel = HomeViewModel(fetchPokemonUseCase: fetchUseCase,
                                      limitRequest: 10,
                                      imageLoader: ImageLoaderUseCaseStub(result: .success(UIImage())))
        let router = HomeRouterSpy()
        let viewController = HomeViewController(viewModel: viewModel, router: router)
        router.viewController = viewController
        trackForMemoryLeaks(instance: viewModel)
        trackForMemoryLeaks(instance: viewController)
        trackForMemoryLeaks(instance: router)

        return (viewController, router)
    }

    func isStillLoading(_ sut: HomeViewController) -> Bool {
        sut.view.subviews.contains(where: { $0 is Spinner })
    }

    @MainActor
    final class HomeRouterSpy: HomeRouterProtocol {
        weak var viewController: UIViewController?
        var didShowError = false
        var didShowDetail = false

        func showError(title: String, message: String) {
            didShowError = true
        }

        func showDetail(id: Int) {
            didShowDetail = true
        }
    }
}
