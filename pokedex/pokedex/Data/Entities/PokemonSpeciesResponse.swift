//
//  PokemonSpeciesResponse.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//

struct PokemonSpeciesResponse: Decodable {
    let flavorTextEntries: [FlavorTextEntry]

    private enum CodingKeys: String, CodingKey {
        case flavorTextEntries = "flavor_text_entries"
    }
}

struct FlavorTextEntry: Decodable {
    let flavorText: String
    let language: NamedAPIResource

    private enum CodingKeys: String, CodingKey {
        case flavorText = "flavor_text"
        case language
    }
}
