//
//  APIError.swift
//  pokedex
//
//  Created by Erik Agujari on 23/10/21.
//

enum APIError: Error {
    case serviceError
    case mappingError
    case cacheError
}

extension APIError: CustomStringConvertible {
    var description: String {
        switch self {
        case .serviceError:
            return "Sorry we had an error on service"
        case .mappingError:
            return "Sorry we cannot map your data successfully"
        case .cacheError:
            return "Sorry your cache is bad"
        }
    }
}
