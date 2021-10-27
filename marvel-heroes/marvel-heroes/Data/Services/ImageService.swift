//
//  ImageService.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 27/10/21.
//

enum ImageService: Service {
    case load(String)
    
    var baseURL: String {
        switch self {
        case let .load(path):
            return path
        }
    }
    
    var path: String? {
        return nil
    }
    
    var parameters: [String : Any]? {
        return nil
    }
    
    var method: ServiceMethod {
        return .get
    }
}
