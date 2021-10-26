//
//  HomeViewModel.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
import UIKit

protocol HomeViewModel {
    var characters: CurrentValueSubject<[MarvelCharacterModel], Never> { get set }
    func fetchInitialCharacters()
    func loadImage(for row: Int, cell: HomeCell)
}

final class HomeViewModelProvider: HomeViewModel {
    private let fetchCharactersUseCase: FetchCharacterUseCase
    private let limitRequest: Int
    private let imageLoader: ImageLoaderUseCase
    private var cancellables = Set<AnyCancellable>()
    var characters = CurrentValueSubject<[MarvelCharacterModel], Never>([MarvelCharacterModel]())
    
    init(fetchCharactersUseCase: FetchCharacterUseCase, limitRequest: Int, imageLoader: ImageLoaderUseCase) {
        self.fetchCharactersUseCase = fetchCharactersUseCase
        self.limitRequest = limitRequest
        self.imageLoader = imageLoader
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
    
    func loadImage(for row: Int, cell: HomeCell) {
        guard let path = characters.value[row].imagePath else { return }
        
        cell.cancelAction = imageLoader.cancel
        imageLoader.fetch(from: path) { result in
            guard let image = try? result.get() else { return }
            
            DispatchQueue.main.async {
                cell.update(image: image)
            }
        }
    }
}

