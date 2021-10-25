//
//  HomeViewModelTests.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
import XCTest
@testable import marvel_heroes

final class HomeViewModelTests: XCTestCase {
    func test_fetchInitialCharacters_doesNotLoadCharactersOnUseCaseError() {
        let sut = makeSUT(fetchUseCaseResult: Fail<[MarvelCharacter], MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher())
        let initialValue = sut.characters.value
        
        sut.fetchInitialCharacters()
        let valueAfterLoad = sut.characters.value
        
        XCTAssertEqual(initialValue, valueAfterLoad)
    }
    
    func test_fetchInitialCharacters_loadsCharactersOnUseCaseSuccess() {
        let sut = makeSUT(fetchUseCaseResult: Just(anyMarvelCharacterList()).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        let initialValue = sut.characters.value
        
        sut.fetchInitialCharacters()
        let valueAfterLoad = sut.characters.value
        
        XCTAssertNotEqual(initialValue, valueAfterLoad)
    }
}

private extension HomeViewModelTests {
    func makeSUT(fetchUseCaseResult: AnyPublisher<[MarvelCharacter], MarvelError>) -> HomeViewModel {
        return HomeViewModelProvider(fetchCharactersUseCase: FetchCharacterUseCaseStub(result: fetchUseCaseResult),
                                     limitRequest: 20)
    }
    
    struct FetchCharacterUseCaseStub: FetchCharacterUseCase {
        let result: AnyPublisher<[MarvelCharacter], MarvelError>
        
        func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError> {
            return result
        }
    }
}

protocol HomeViewModel {
    var characters: CurrentValueSubject<[MarvelCharacterModel], MarvelError> { get set }
    func fetchInitialCharacters()
}

struct MarvelCharacterModel: Equatable {
    init(from character: MarvelCharacter) {
        
    }
}

final class HomeViewModelProvider: HomeViewModel {
    private let fetchCharactersUseCase: FetchCharacterUseCase
    private let limitRequest: Int
    private var cancellables = Set<AnyCancellable>()
    var characters = CurrentValueSubject<[MarvelCharacterModel], MarvelError>([MarvelCharacterModel]())
    
    init(fetchCharactersUseCase: FetchCharacterUseCase, limitRequest: Int) {
        self.fetchCharactersUseCase = fetchCharactersUseCase
        self.limitRequest = limitRequest
    }
    
    func fetchInitialCharacters() {
        fetchCharactersUseCase.execute(limit: limitRequest, offset: 0)
            .sink { result in
                print(result)
            } receiveValue: { [weak self] characters in
                let models = characters.map { MarvelCharacterModel(from: $0) }
                self?.characters.send(models)
            }
            .store(in: &cancellables)
    }
}
