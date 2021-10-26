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
    
    func test_loadView_UpdatesTableViewOnViewModelSuccess() {
        let list = anyMarvelCharacterList()
        let sut = makeSUT(initialResult: Just(list).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.tableView(sut.tableView, numberOfRowsInSection: 0), list.count)
    }
}

private extension HomeIntegrationTests {
    func makeSUT(initialResult: AnyPublisher<[MarvelCharacter], MarvelError>) -> (HomeViewController) {
        let viewModel = HomeViewModelProvider(fetchCharactersUseCase: FetchCharacterUseCaseStub(result: initialResult), limitRequest: 10)
        let viewController = HomeViewController(viewModel: viewModel)
        
        return viewController
    }
}
