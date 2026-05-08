//
//  PokemonRepositoryTests+JSONMock.swift
//  pokedexTests
//
//  Created by Erik Agujari on 24/10/21.
//
import Foundation

extension PokemonRepositoryTests {
    func anyInvalidJSON() -> Data? {
        let json = """
            {
                "count": 0,
                "next": null,
                "previous": null
            }
        """

        return json.data(using: .utf8)
    }

    func anyValidPokemonListJSON() -> Data? {
        let json = """
        {
          "count": 1302,
          "next": "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
          "previous": null,
          "results": [
            { "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/" },
            { "name": "ivysaur", "url": "https://pokeapi.co/api/v2/pokemon/2/" },
            { "name": "venusaur", "url": "https://pokeapi.co/api/v2/pokemon/3/" }
          ]
        }
        """

        return json.data(using: .utf8)
    }

    func anyValidPokemonDetailJSON() -> Data? {
        let json = """
        {
          "id": 1,
          "name": "bulbasaur",
          "sprites": {
            "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"
          },
          "types": [
            { "slot": 1, "type": { "name": "grass", "url": "https://pokeapi.co/api/v2/type/12/" } },
            { "slot": 2, "type": { "name": "poison", "url": "https://pokeapi.co/api/v2/type/4/" } }
          ]
        }
        """

        return json.data(using: .utf8)
    }

    func anyValidPokemonSpeciesJSON() -> Data? {
        let json = """
        {
          "flavor_text_entries": [
            { "flavor_text": "A strange seed was planted on its back at birth.", "language": { "name": "en", "url": "https://pokeapi.co/api/v2/language/9/" } },
            { "flavor_text": "Pour son dos une drôle de graine.", "language": { "name": "fr", "url": "https://pokeapi.co/api/v2/language/5/" } }
          ]
        }
        """

        return json.data(using: .utf8)
    }
}
