//
//  HomeViewModel.swift
//  pokedex
//
//  Created by Erik Agujari on 25/10/21.
//

import Observation

@MainActor
protocol HomeViewModelProtocol: BaseViewModel, Observable {
    var characters: [Pokemon] { get }
    var title: String { get }
    func fetchInitialCharacters() async
    func willDisplayItemAt(_ index: Int) async
    func refresh() async
}

@Observable @MainActor
final class HomeViewModel: HomeViewModelProtocol {
    @ObservationIgnored private let fetchPokemonUseCase: FetchPokemonUseCase
    @ObservationIgnored private let limitRequest: Int

    private(set) var characters: [Pokemon] = []
    private(set) var title: String = "Pokédex"
    var isLoading: Bool = false
    var errorAlert: ErrorAlert?

    init(fetchPokemonUseCase: FetchPokemonUseCase, limitRequest: Int) {
        self.fetchPokemonUseCase = fetchPokemonUseCase
        self.limitRequest = limitRequest
    }

    func fetchInitialCharacters() async {
        await loadCharacters(offset: 0)
    }

    func refresh() async {
        await loadCharacters(offset: 0, reset: true)
    }

    func willDisplayItemAt(_ index: Int) async {
        guard characters.indices.contains(index),
              let last = characters.last,
              characters[index] == last else { return }
        await loadCharacters(offset: characters.count)
    }

    private func loadCharacters(offset: Int, reset: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let new = try await fetchPokemonUseCase.execute(limit: limitRequest, offset: offset)
            characters = reset ? new : characters + new
        } catch let error as APIError {
            errorAlert = ErrorAlert(title: Constants.errorTitle, message: error.description)
        } catch {
            errorAlert = ErrorAlert(title: Constants.errorTitle, message: APIError.serviceError.description)
        }
    }
}

private extension HomeViewModel {
    enum Constants {
        static let errorTitle = "!Oops, we had an error!"
    }
}
