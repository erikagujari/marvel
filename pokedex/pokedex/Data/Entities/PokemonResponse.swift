//
//  PokemonResponse.swift
//  pokedex
//
//  Created by Erik Agujari on 23/10/21.
//

import Foundation

struct PokemonListResponse: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonListItem]
}

struct PokemonListItem: Decodable {
    let name: String
    let url: String
}

struct PokemonDetailResponse: Decodable {
    let id: Int
    let name: String
    let sprites: PokemonSprites
    let types: [PokemonTypeSlot]
}

struct PokemonSprites: Decodable {
    let frontDefault: String?

    private enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
    }
}

struct PokemonTypeSlot: Decodable {
    let type: NamedAPIResource
}

struct NamedAPIResource: Decodable {
    let name: String
    let url: String
}
