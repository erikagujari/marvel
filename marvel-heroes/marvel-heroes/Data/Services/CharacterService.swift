//
//  CharacterService.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Foundation

enum CharacterService: Service {
    struct AuthorizationParameters {
        let apiKey: String
        let timestamp: String
        let hash: String
    }
    
    struct ListParameters {
        let limit: Int
        let offset: Int
    }
    
    case list(parameters: ListParameters, authorization: AuthorizationParameters)
    case detail(id: Int, authorization: AuthorizationParameters)
    
    var baseURL: String {
        return "https://gateway.marvel.com:443"
    }
    
    var path: String? {
        switch self {
        case .list:
            return "/v1/public/characters"
        case let .detail(id, _):
            return "/v1/public/characters/\(id)"
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case let .list(parameters, authorization):
            var dictionary = dictionary(from: authorization)
            dictionary["limit"] = String(parameters.limit)
            dictionary["offset"] = String(parameters.offset)
            
            return dictionary
        case let .detail(_, authorization):
            return dictionary(from: authorization)
        }
    }
    
    var method: ServiceMethod {
        return .get
    }
    
    private func dictionary(from authorization: AuthorizationParameters) -> [String: Any] {
        var dictionary = [String: Any]()
        dictionary["apikey"] = authorization.apiKey
        dictionary["ts"] = authorization.timestamp
        dictionary["hash"] = authorization.hash
        
        return dictionary
    }
}

