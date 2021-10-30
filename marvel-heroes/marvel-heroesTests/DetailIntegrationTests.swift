//
//  DetailIntegrationTests.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 30/10/21.
//

import Combine
import XCTest
@testable import marvel_heroes

final class DetailIntegrationTests: XCTestCase {
    func test_loadView_showsSpinnerOnImageView() {
        let (sut, _) = makeSUT(characterDetailResult: Just(anyCharacterDetail()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          imageResult: Just(UIImage()).delay(for: 3, scheduler: RunLoop.main).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        
        sut.loadViewIfNeeded()
        
        XCTAssertNotNil(sut.imageView.subviews.first(where: { $0 is Spinner }))
    }
    
    func test_loadView_dismissesSpinnerOnImageViewWhenCompleted() {
        let imageResult = Just(UIImage()).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
        let (sut, _) = makeSUT(characterDetailResult: Just(anyCharacterDetail()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(),
                          imageResult: imageResult)
        let exp = expectation(description: "Waiting to complete image")
        var cancellabes = Set<AnyCancellable>()
        
        sut.loadViewIfNeeded()
        
        imageResult
            .receive(on: DispatchQueue.main)
            .sink { result in
                XCTAssertNil(sut.imageView.subviews.first(where: { $0 is Spinner }))
                exp.fulfill()
            } receiveValue: { _ in }.store(in: &cancellabes)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadView_updatesUIOnUseCaseCompletion() {
        let characterDetail = anyCharacterDetail()
        let characterDetailResult = Just(characterDetail).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
        let (sut, _) = makeSUT(characterDetailResult: characterDetailResult,
                          imageResult: Just(UIImage()).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to complete character detail")
        var cancellabes = Set<AnyCancellable>()
        
        sut.loadViewIfNeeded()
        
        characterDetailResult
            .receive(on: DispatchQueue.main)
            .sink { result in
                XCTAssertEqual(sut.titleLabel.text, characterDetail.name)
                XCTAssertEqual(sut.descriptionLabel.text, characterDetail.description)
                exp.fulfill()
            } receiveValue: { _ in
                
            }
            .store(in: &cancellabes)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_loadView_showsErrorOnUseCaseError() {
        let characterDetailResult = Fail<CharacterDetail, MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher()
        let (viewController, router) = makeSUT(characterDetailResult: characterDetailResult,
                                               imageResult: Just(UIImage()).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to complete character detail")
        var cancellabes = Set<AnyCancellable>()
        
        viewController.loadViewIfNeeded()
        characterDetailResult
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                XCTAssertTrue(router.isDismissing)
                exp.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellabes)
        
        wait(for: [exp], timeout: 1.0)
    }
}

private extension DetailIntegrationTests {
    func makeSUT(characterDetailResult: AnyPublisher<CharacterDetail, MarvelError>, imageResult: AnyPublisher<UIImage, MarvelError>) -> (DetailViewController, DetailRouterStub) {
        let router = DetailRouterStub()
        let useCase = FetchCharacterDetailUseCaseStub(result: characterDetailResult)
        let imageLoader = ImageLoaderUseCaseStub(result: imageResult)
        let viewModel = DetailViewModel(id: 0, fetchUseCase: useCase, imageLoader: imageLoader)
        let viewController = DetailViewController(viewModel: viewModel, router: router)
        router.viewController = viewController
        trackForMemoryLeaks(instance: viewController)
        trackForMemoryLeaks(instance: viewModel)
        trackForMemoryLeaks(instance: router)
        
        return (viewController, router)
    }
    
    struct FetchCharacterDetailUseCaseStub: FetchCharacterDetailUseCase {
        let result: AnyPublisher<CharacterDetail, MarvelError>
        
        func execute(id: Int) -> AnyPublisher<CharacterDetail, MarvelError> {
            return result
        }
    }
    
    func anyCharacterDetail() -> CharacterDetail {
        return CharacterDetail(name: "John", description: "Snow", comics: [], imagePath: "Any image path")
    }
    
    class DetailRouterStub: DetailRouterProtocol {
        weak var viewController: UIViewController?
        
        var isDismissing = false
        
        func showError(title: String, message: String) {
            isDismissing = true
        }
    }
}
