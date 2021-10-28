//
//  HomeIntegrationTests.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 26/10/21.
//
import Combine
import XCTest
@testable import marvel_heroes

final class HomeIntegrationTests: XCTestCase {
    func test_loadView_doesNotUpdateTableViewOnViewModelError() {
        let (sut, _) = makeSUT(initialResult: Fail<[MarvelCharacterResponse], MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher())
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: 0), 0)
    }
    
    func test_loadView_updatesTableViewOnViewModelSuccess_andDoesNotShowSpinner() {
        let list = anyMarvelCharacterList()
        let (sut, _) = makeSUT(initialResult: Just(list).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: 0), list.count)
        XCTAssertNil(sut.view.subviews.first(where: { $0 is Spinner }))
    }
    
    func test_loadView_showsSpinnerOnDelay() {
        let list = anyMarvelCharacterList()
        let (sut, _) = makeSUT(initialResult: Just(list).setFailureType(to: MarvelError.self).eraseToAnyPublisher(), delay: 1)
        let exp = expectation(description: "Waiting for showing spinner")
        sut.loadViewIfNeeded()
                
        DispatchQueue.main.async {
            XCTAssertNotNil(sut.view.subviews.first(where: { $0 is Spinner }))
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
    
    func test_loadView_showsErrorOnViewModelError() {
        let (sut, router) = makeSUT(initialResult: Fail<[MarvelCharacterResponse], MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to show error")
        
        router.showedErrorAction = {
            exp.fulfill()
        }
        sut.loadViewIfNeeded()
        
        wait(for: [exp], timeout: 1.0)
    }
}

private extension HomeIntegrationTests {
    func makeSUT(initialResult: AnyPublisher<[MarvelCharacterResponse], MarvelError>, delay: Double? = nil) -> (HomeViewController, HomeRouterSpy) {
        let fetchCharacterUseCase = FetchCharacterUseCaseStub(firstLoadResult: initialResult, delay: delay)
        let viewModel = HomeViewModel(fetchCharactersUseCase: fetchCharacterUseCase,
                                              limitRequest: 10,
                                              imageLoader: ImageLoaderUseCaseStub(result: Just(UIImage()).setFailureType(to: MarvelError.self).eraseToAnyPublisher()))
        let router = HomeRouterSpy()
        let viewController = HomeViewController(viewModel: viewModel, router: router)
        router.viewController = viewController
        trackForMemoryLeaks(instance: viewModel)
        trackForMemoryLeaks(instance: viewController)
        trackForMemoryLeaks(instance: router)
        
        return (viewController, router)
    }
    
    class HomeRouterSpy: HomeRouterProtocol {
        weak var viewController: UIViewController?
        var showedErrorAction: (() -> Void)?
        
        func showError(title: String, message: String) {
            showedErrorAction?()
        }
    }
}
