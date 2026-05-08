//
//  FetchPokemonUseCase.swift
//  pokedex
//
//  Created by Erik Agujari on 24/10/21.
//
import Foundation

protocol FetchPokemonUseCase: Sendable {
    func execute(limit: Int, offset: Int) async throws -> [Pokemon]
}

struct FetchPokemonUseCaseProvider: FetchPokemonUseCase {
    private let repository: PokemonRepository

    init(repository: PokemonRepository) {
        self.repository = repository
    }

    func execute(limit: Int, offset: Int) async throws -> [Pokemon] {
        let pokemon = try await repository.fetch(offset: offset, limit: limit)
        guard !pokemon.isEmpty else { throw APIError.serviceError }
        return pokemon
    }
}
