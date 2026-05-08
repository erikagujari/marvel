//
//  PokemonRepository.swift
//  pokedex
//
//  Created by Erik Agujari on 23/10/21.
//

protocol PokemonRepository: Sendable {
    func fetch(offset: Int, limit: Int) async throws -> [Pokemon]
    func fetchDetail(id: Int) async throws -> PokemonDetail
}

struct PokemonRepositoryProvider: PokemonRepository {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetch(offset: Int, limit: Int) async throws -> [Pokemon] {
        let response = try await httpClient.fetch(
            PokemonService.list(offset: offset, limit: limit),
            responseType: PokemonListResponse.self
        )
        return response.results.compactMap(Pokemon.init(from:))
    }

    func fetchDetail(id: Int) async throws -> PokemonDetail {
        async let detail = httpClient.fetch(
            PokemonService.detail(id: id),
            responseType: PokemonDetailResponse.self
        )
        async let species = httpClient.fetch(
            PokemonService.species(id: id),
            responseType: PokemonSpeciesResponse.self
        )
        return PokemonDetail(detail: try await detail, species: try await species)
    }
}
