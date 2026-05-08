//
//  DetailViewModel.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//

import Combine
import UIKit

protocol DetailViewModelProtocol: BaseViewModel {
    var pokemonDetail: PassthroughSubject<PokemonDetail, Never> { get set }
    var loadedImage: PassthroughSubject<UIImage, Never> { get set }
    func fetchDetail()
}

final class DetailViewModel {
    private let id: Int
    private let fetchUseCase: FetchPokemonDetailUseCase
    private let imageLoader: ImageLoaderUseCase
    private var cancellables = Set<AnyCancellable>()
    var showError = PassthroughSubject<(String, String), Never>()
    var showSpinner = PassthroughSubject<Bool, Never>()
    var pokemonDetail = PassthroughSubject<PokemonDetail, Never>()
    var loadedImage = PassthroughSubject<UIImage, Never>()

    init(id: Int, fetchUseCase: FetchPokemonDetailUseCase, imageLoader: ImageLoaderUseCase) {
        self.id = id
        self.fetchUseCase = fetchUseCase
        self.imageLoader = imageLoader
    }

    private func loadImage(path: String?) {
        guard let path = path else { return }

        imageLoader.fetch(from: path)
            .sink { [weak self] result in
                if case .failure = result,
                   let image = UIImage(named: "wifi") {
                    self?.loadedImage.send(image)
                }
            } receiveValue: { [weak self] image in
                self?.loadedImage.send(image)
            }
            .store(in: &cancellables)
    }
}

extension DetailViewModel: DetailViewModelProtocol {
    func fetchDetail() {
        showSpinner.send(true)
        fetchUseCase.execute(id: id)
            .sink { [weak self] result in
                self?.showSpinner.send(false)
                if case let .failure(error) = result {
                    self?.showError.send((Constants.errorTitle, error.description))
                }
            } receiveValue: { [weak self] pokemon in
                self?.pokemonDetail.send(pokemon)
                self?.loadImage(path: pokemon.imageURL)
            }
            .store(in: &cancellables)
    }
}

private extension DetailViewModel {
    enum Constants {
        static let errorTitle = "¡Oops, we had an error retrieving your Pokémon!"
    }
}
