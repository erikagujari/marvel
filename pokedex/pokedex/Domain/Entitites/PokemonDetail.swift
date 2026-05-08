//
//  PokemonDetail.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//

import Foundation

struct PokemonDetail: Equatable, Sendable {
    let id: Int
    let name: String
    let imageURL: String?
    let types: [String]
    let description: String?

    init(id: Int, name: String, imageURL: String?, types: [String], description: String?) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.types = types
        self.description = description
    }

    init(detail: PokemonDetailResponse, species: PokemonSpeciesResponse) {
        self.id = detail.id
        self.name = detail.name.capitalized
        self.imageURL = detail.sprites.frontDefault ?? Pokemon.artworkURL(for: detail.id)
        self.types = detail.types.map { $0.type.name.capitalized }
        self.description = species.flavorTextEntries
            .first(where: { $0.language.name == "en" })?
            .flavorText
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\u{0C}", with: " ")
    }
}
