//
//  CharacterService.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Foundation

enum CharacterService: Service {
    case list(limit: Int, offset: Int)
    
    var baseURL: String {
        return "https://gateway.marvel.com:443/"
    }
    var path: String {
        switch self {
        case .list:
            return "/v1/public/characters"
        }
    }
    
    var parameters: [String : Any]? {
        switch self {
        case let .list(limit, offset):
            var dictionary = [String: Any]()
            dictionary["limit"] = limit
            dictionary["offset"] = offset
            dictionary["apikey"] = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String ?? ""
            
            return dictionary
        }
    }
    
    var method: ServiceMethod {
        return .get
    }
}

