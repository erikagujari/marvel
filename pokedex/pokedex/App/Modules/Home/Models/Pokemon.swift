//
//  Pokemon.swift
//  pokedex
//
//  Created by Erik Agujari on 25/10/21.
//

struct Pokemon: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let imageURL: String?

    init(id: Int, name: String, imageURL: String?) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
    }

    init?(from listItem: PokemonListItem) {
        guard let parsedId = Pokemon.id(from: listItem.url) else { return nil }
        self.id = parsedId
        self.name = listItem.name.capitalized
        self.imageURL = Pokemon.artworkURL(for: parsedId)
    }

    static func id(from url: String) -> Int? {
        let components = url.split(separator: "/").map(String.init)
        return components.last.flatMap(Int.init)
    }

    static func artworkURL(for id: Int) -> String {
        return "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(id).png"
    }
}
