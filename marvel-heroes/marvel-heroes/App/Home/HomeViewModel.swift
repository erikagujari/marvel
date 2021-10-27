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
    var showSpinner: PassthroughSubject<Bool, Never> { get set }
    var title: CurrentValueSubject<String, Never> { get set }
    func fetchInitialCharacters()
    func cellModel(for index: Int, imageAction: @escaping (UIImage) -> Void) -> HomeCellModel
    func willDisplayItemAt(_ index: Int)
}

final class HomeViewModelProvider {
    private let fetchCharactersUseCase: FetchCharacterUseCase
    private let limitRequest: Int
    private let imageLoader: ImageLoaderUseCase
    private var cancellables = Set<AnyCancellable>()
    private var cancellableImages = [AnyCancellable]()
    var characters = CurrentValueSubject<[MarvelCharacterModel], Never>([MarvelCharacterModel]())
    var showSpinner = PassthroughSubject<Bool, Never>()
    var title = CurrentValueSubject<String, Never>("Heroes")
    
    init(fetchCharactersUseCase: FetchCharacterUseCase, limitRequest: Int, imageLoader: ImageLoaderUseCase) {
        self.fetchCharactersUseCase = fetchCharactersUseCase
        self.limitRequest = limitRequest
        self.imageLoader = imageLoader
    }
    
    private func assignImageFrom(path: String, to imageAction: @escaping (UIImage) -> Void) {
        imageLoader.fetch(from: path)
            .receive(on: RunLoop.main)
            .sink { _ in }
            receiveValue: { image in
                imageAction(image)
            }
            .store(in: &cancellableImages)
    }
    
    private func loadCharacters(offset: Int) {
        showSpinner.send(true)
        fetchCharactersUseCase.execute(limit: limitRequest, offset: offset)
            .sink { [weak self] result in
                self?.showSpinner.send(false)
            } receiveValue: { [weak self] newCharacters in
                guard let self = self else { return }
                
                let models = self.characters.value + newCharacters.compactMap { MarvelCharacterModel(from: $0) }
                self.characters.send(models)
            }
            .store(in: &cancellables)
    }
}

extension HomeViewModelProvider: HomeViewModel {
    func fetchInitialCharacters() {
        loadCharacters(offset: 0)
    }
    
    func cellModel(for index: Int, imageAction: @escaping (UIImage) -> Void) -> HomeCellModel {
        let model = characters.value[index]
        guard let path = model.imagePath else {
            return HomeCellModel(title: model.name, description: model.description, cancelAction: nil)
        }
        
        assignImageFrom(path: path, to: imageAction)
        return HomeCellModel(title: model.name, description: model.description, cancelAction: { [weak self] in
            self?.cancellableImages[index].cancel()
        })
    }
    
    func willDisplayItemAt(_ index: Int) {
        let characters = characters.value
        guard let last = characters.last, characters[index] == last else { return }
        
        loadCharacters(offset: characters.count)
    }
}
