//
//  FetchPokemonDetailUseCase.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//
import Combine

protocol FetchPokemonDetailUseCase {
    func execute(id: Int) -> AnyPublisher<PokemonDetail, APIError>
}

struct FetchPokemonDetailUseCaseProvider: FetchPokemonDetailUseCase {
    private let repository: PokemonRepository

    init(repository: PokemonRepository) {
        self.repository = repository
    }

    func execute(id: Int) -> AnyPublisher<PokemonDetail, APIError> {
        return repository.fetchDetail(id: id)
    }
}
