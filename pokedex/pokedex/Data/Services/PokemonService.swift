//
//  PokemonService.swift
//  pokedex
//
//  Created by Erik Agujari on 23/10/21.
//

import Foundation

enum PokemonService: Service {
    case list(offset: Int, limit: Int)
    case detail(id: Int)
    case species(id: Int)

    var baseURL: String {
        return "https://pokeapi.co"
    }

    var path: String? {
        switch self {
        case .list:
            return "/api/v2/pokemon"
        case let .detail(id):
            return "/api/v2/pokemon/\(id)"
        case let .species(id):
            return "/api/v2/pokemon-species/\(id)"
        }
    }

    var parameters: [String: String]? {
        switch self {
        case let .list(offset, limit):
            return ["offset": String(offset), "limit": String(limit)]
        case .detail, .species:
            return nil
        }
    }

    var method: ServiceMethod {
        return .get
    }
}
