//
//  HomeViewModel.swift
//  pokedex
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
import UIKit

@MainActor
protocol HomeViewModelProtocol: BaseViewModel {
    var characters: CurrentValueSubject<[Pokemon], Never> { get set }
    var title: CurrentValueSubject<String, Never> { get set }
    func fetchInitialCharacters()
    func cellModel(for index: Int, imageAction: @escaping (UIImage) -> Void) -> HomeCellModel
    func willDisplayItemAt(_ index: Int)
    func refresh()
    func idForRowAt(_ index: Int) -> Int
}

@MainActor
final class HomeViewModel {
    private let fetchPokemonUseCase: FetchPokemonUseCase
    private let limitRequest: Int
    private let imageLoader: ImageLoaderUseCase
    private var cancellables = Set<AnyCancellable>()
    private var cancellableImages = [Int: AnyCancellable]()
    var characters = CurrentValueSubject<[Pokemon], Never>([Pokemon]())
    var title = CurrentValueSubject<String, Never>("Pokédex")
    var showError = PassthroughSubject<(String, String), Never>()
    var showSpinner = PassthroughSubject<Bool, Never>()

    init(fetchPokemonUseCase: FetchPokemonUseCase, limitRequest: Int, imageLoader: ImageLoaderUseCase) {
        self.fetchPokemonUseCase = fetchPokemonUseCase
        self.limitRequest = limitRequest
        self.imageLoader = imageLoader
    }

    private func assignImageFrom(path: String, id: Int, to imageAction: @escaping (UIImage) -> Void) {
        cancellableImages[id]?.cancel()
        cancellableImages[id] = imageLoader.fetch(from: path)
            .receive(on: RunLoop.main)
            .sink { [weak self] result in
                if case .failure = result,
                   let image = UIImage(named: "wifi") {
                    imageAction(image)
                }
                self?.cancellableImages[id] = nil
            }
            receiveValue: { image in
                imageAction(image)
            }
    }

    private func loadCharacters(offset: Int) {
        showSpinner.send(true)
        fetchPokemonUseCase.execute(limit: limitRequest, offset: offset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                if case let .failure(error) = result {
                    self?.showError.send((Constants.errorTitle, error.description))
                }
                self?.showSpinner.send(false)
            } receiveValue: { [weak self] newPokemon in
                guard let self = self else { return }

                let models = self.characters.value + newPokemon
                self.characters.send(models)
            }
            .store(in: &cancellables)
    }
}

extension HomeViewModel: HomeViewModelProtocol {
    func fetchInitialCharacters() {
        loadCharacters(offset: 0)
    }

    func cellModel(for index: Int, imageAction: @escaping (UIImage) -> Void) -> HomeCellModel {
        let snapshot = characters.value
        guard snapshot.indices.contains(index) else {
            return HomeCellModel(title: "", description: nil, cancelAction: nil)
        }
        let model = snapshot[index]
        guard let path = model.imageURL else {
            return HomeCellModel(title: model.name, description: nil, cancelAction: nil)
        }

        assignImageFrom(path: path, id: model.id, to: imageAction)
        return HomeCellModel(title: model.name, description: nil, cancelAction: { [weak self] in
            self?.cancellableImages[model.id]?.cancel()
            self?.cancellableImages[model.id] = nil
        })
    }

    func willDisplayItemAt(_ index: Int) {
        let characters = characters.value
        guard characters.indices.contains(index),
              let last = characters.last,
              characters[index] == last else { return }

        loadCharacters(offset: characters.count)
    }

    func refresh() {
        loadCharacters(offset: characters.value.count)
    }

    func idForRowAt(_ index: Int) -> Int {
        let snapshot = characters.value
        guard snapshot.indices.contains(index) else { return -1 }
        return snapshot[index].id
    }
}

private extension HomeViewModel {
    enum Constants {
        static let errorTitle = "!Oops, we had an error!"
    }
}
