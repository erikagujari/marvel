//
//  FetchPokemonUseCase.swift
//  pokedex
//
//  Created by Erik Agujari on 24/10/21.
//
import Combine
import Foundation

protocol FetchPokemonUseCase {
    func execute(limit: Int, offset: Int) -> AnyPublisher<[Pokemon], APIError>
}

struct FetchPokemonUseCaseProvider: FetchPokemonUseCase {
    private let repository: PokemonRepository

    init(repository: PokemonRepository) {
        self.repository = repository
    }

    func execute(limit: Int, offset: Int) -> AnyPublisher<[Pokemon], APIError> {
        return repository.fetch(offset: offset, limit: limit)
            .flatMap { pokemon -> AnyPublisher<[Pokemon], APIError> in
                guard !pokemon.isEmpty else {
                    return Fail(error: APIError.serviceError).eraseToAnyPublisher()
                }
                return Just(pokemon).setFailureType(to: APIError.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
