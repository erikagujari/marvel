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
        let sut = makeSUT(initialResult: Fail<[MarvelCharacter], MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher())
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: 0), 0)
    }
    
    func test_loadView_updatesTableViewOnViewModelSuccess_andDoesNotShowSpinner() {
        let list = anyMarvelCharacterList()
        let sut = makeSUT(initialResult: Just(list).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: 0), list.count)
        XCTAssertNil(sut.view.subviews.first(where: { $0 is Spinner }))
    }
    
    func test_loadView_showsSpinnerOnDelay() {
        let list = anyMarvelCharacterList()
        let sut = makeSUT(initialResult: Just(list).setFailureType(to: MarvelError.self).eraseToAnyPublisher(), delay: 1)
        let exp = expectation(description: "Waiting for showing spinner")
        sut.loadViewIfNeeded()
                
        DispatchQueue.main.async {
            XCTAssertNotNil(sut.view.subviews.first(where: { $0 is Spinner }))
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1)
    }
}

private extension HomeIntegrationTests {
    func makeSUT(initialResult: AnyPublisher<[MarvelCharacter], MarvelError>, delay: Double? = nil) -> HomeViewController {
        let fetchCharacterUseCase = FetchCharacterUseCaseStub(firstLoadResult: initialResult, delay: delay)
        let viewModel = HomeViewModelProvider(fetchCharactersUseCase: fetchCharacterUseCase,
                                              limitRequest: 10,
                                              imageLoader: ImageLoaderUseCaseStub(result: Just(UIImage()).setFailureType(to: MarvelError.self).eraseToAnyPublisher()))
        let viewController = HomeViewController(viewModel: viewModel)
        trackForMemoryLeaks(instance: viewModel)
        trackForMemoryLeaks(instance: viewController)
        
        return viewController
    }        
}
