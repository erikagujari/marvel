//
//  PokemonRepository.swift
//  pokedex
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine

protocol PokemonRepository {
    func fetch(offset: Int, limit: Int) -> AnyPublisher<[Pokemon], APIError>
    func fetchDetail(id: Int) -> AnyPublisher<PokemonDetail, APIError>
}

struct PokemonRepositoryProvider: PokemonRepository {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetch(offset: Int, limit: Int) -> AnyPublisher<[Pokemon], APIError> {
        return httpClient.fetch(PokemonService.list(offset: offset, limit: limit), responseType: PokemonListResponse.self)
            .map { response in
                return response.results.compactMap(Pokemon.init(from:))
            }
            .eraseToAnyPublisher()
    }

    func fetchDetail(id: Int) -> AnyPublisher<PokemonDetail, APIError> {
        let detail = httpClient.fetch(PokemonService.detail(id: id), responseType: PokemonDetailResponse.self)
        let species = httpClient.fetch(PokemonService.species(id: id), responseType: PokemonSpeciesResponse.self)

        return Publishers.Zip(detail, species)
            .map { PokemonDetail(detail: $0.0, species: $0.1) }
            .eraseToAnyPublisher()
    }
}
