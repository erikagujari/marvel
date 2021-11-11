//
//  MarvelError.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//

enum MarvelError: Error {
    case serviceError
    case mappingError
    case apiKeyError
    case cacheError
}

extension MarvelError: CustomStringConvertible {
    var description: String {
        switch self {
        case .serviceError:
            return "Sorry we had an error on service"
        case .mappingError:
            return "Sorry we cannot map your data successfully"
        case .apiKeyError:
            return "Sorry your app is not connected to Marvel API"
        case .cacheError:
            return "Sorry your cache is bad"
        }
    }
}
