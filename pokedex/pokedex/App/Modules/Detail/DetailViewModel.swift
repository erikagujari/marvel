//
//  DetailViewModel.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//

import UIKit

@MainActor
protocol DetailViewModelProtocol: BaseViewModel {
    var pokemon: PokemonDetail? { get }
    var image: UIImage? { get }
    func fetchDetail() async
}

@Observable @MainActor
final class DetailViewModel: DetailViewModelProtocol {
    @ObservationIgnored private let id: Int
    @ObservationIgnored private let fetchUseCase: FetchPokemonDetailUseCase
    @ObservationIgnored private let imageLoader: ImageLoaderUseCase

    private(set) var pokemon: PokemonDetail?
    private(set) var image: UIImage?
    var isLoading: Bool = false
    var errorAlert: ErrorAlert?

    init(id: Int, fetchUseCase: FetchPokemonDetailUseCase, imageLoader: ImageLoaderUseCase) {
        self.id = id
        self.fetchUseCase = fetchUseCase
        self.imageLoader = imageLoader
    }

    func fetchDetail() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let detail = try await fetchUseCase.execute(id: id)
            pokemon = detail
            await loadImage(path: detail.imageURL)
        } catch let error as APIError {
            errorAlert = ErrorAlert(title: Constants.errorTitle, message: error.description)
        } catch {
            errorAlert = ErrorAlert(title: Constants.errorTitle, message: APIError.serviceError.description)
        }
    }

    private func loadImage(path: String?) async {
        guard let path = path else { return }
        do {
            image = try await imageLoader.fetch(from: path)
        } catch {
            image = UIImage(named: "wifi")
        }
    }
}

private extension DetailViewModel {
    enum Constants {
        static let errorTitle = "¡Oops, we had an error retrieving your Pokémon!"
    }
}
