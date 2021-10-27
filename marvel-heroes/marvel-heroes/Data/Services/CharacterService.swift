//
//  CharacterService.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Foundation

enum CharacterService: Service {
    struct ListParameters {
        let limit: Int
        let offset: Int
        let apiKey: String
        let timestamp: String
        let hash: String
    }
    case list(parameters: ListParameters)
    
    var baseURL: String {
        return "https://gateway.marvel.com:443"
    }
    
    var path: String? {
        switch self {
        case .list:
            return "/v1/public/characters"
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case let .list(parameters):
            var dictionary = [String: Any]()
            dictionary["limit"] = String(parameters.limit)
            dictionary["offset"] = String(parameters.offset)
            dictionary["apikey"] = parameters.apiKey
            dictionary["ts"] = parameters.timestamp
            dictionary["hash"] = parameters.hash
            
            return dictionary
        }
    }
    
    var method: ServiceMethod {
        return .get
    }
}

