//
//  DetailViewModel.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//

import Observation

@MainActor
protocol DetailViewModelProtocol: BaseViewModel, Observable {
    var pokemon: PokemonDetail? { get }
    func fetchDetail() async
}

@Observable @MainActor
final class DetailViewModel: DetailViewModelProtocol {
    @ObservationIgnored private let id: Int
    @ObservationIgnored private let fetchUseCase: FetchPokemonDetailUseCase

    private(set) var pokemon: PokemonDetail?
    var isLoading: Bool = false
    var errorAlert: ErrorAlert?

    init(id: Int, fetchUseCase: FetchPokemonDetailUseCase) {
        self.id = id
        self.fetchUseCase = fetchUseCase
    }

    func fetchDetail() async {
        isLoading = true
        defer { isLoading = false }
        do {
            pokemon = try await fetchUseCase.execute(id: id)
        } catch let error as APIError {
            errorAlert = ErrorAlert(title: Constants.errorTitle, message: error.description)
        } catch {
            errorAlert = ErrorAlert(title: Constants.errorTitle, message: APIError.serviceError.description)
        }
    }
}

private extension DetailViewModel {
    enum Constants {
        static let errorTitle = "¡Oops, we had an error retrieving your Pokémon!"
    }
}
