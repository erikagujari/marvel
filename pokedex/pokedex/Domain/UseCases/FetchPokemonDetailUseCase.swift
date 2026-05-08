//
//  FetchPokemonDetailUseCase.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//

protocol FetchPokemonDetailUseCase: Sendable {
    func execute(id: Int) async throws -> PokemonDetail
}

struct FetchPokemonDetailUseCaseProvider: FetchPokemonDetailUseCase {
    private let repository: PokemonRepository

    init(repository: PokemonRepository) {
        self.repository = repository
    }

    func execute(id: Int) async throws -> PokemonDetail {
        try await repository.fetchDetail(id: id)
    }
}
