//
//  HomeViewModel.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine

protocol HomeViewModel {
    var characters: CurrentValueSubject<[MarvelCharacterModel], Never> { get set }
    func fetchInitialCharacters()
}

final class HomeViewModelProvider: HomeViewModel {
    private let fetchCharactersUseCase: FetchCharacterUseCase
    private let limitRequest: Int
    private var cancellables = Set<AnyCancellable>()
    var characters = CurrentValueSubject<[MarvelCharacterModel], Never>([MarvelCharacterModel]())
    
    init(fetchCharactersUseCase: FetchCharacterUseCase, limitRequest: Int) {
        self.fetchCharactersUseCase = fetchCharactersUseCase
        self.limitRequest = limitRequest
    }
    
    func fetchInitialCharacters() {
        fetchCharactersUseCase.execute(limit: limitRequest, offset: 0)
            .sink { result in
                print(result)
            } receiveValue: { [weak self] characters in
                let models = characters.compactMap { MarvelCharacterModel(from: $0) }
                self?.characters.send(models)
            }
            .store(in: &cancellables)
    }
}

