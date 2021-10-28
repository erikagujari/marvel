//
//  CharacterDetail.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//

struct CharacterDetail {
    let name: String
    let description: String?
    let comics: [String]?
    let imagePath: String?
    
    init?(from response: MarvelCharacterResponse) {
        guard let name = response.name else { return nil }
        
        self.name = name
        description = response.description
        comics = response.comics.map { $0.items.map { $0.name } }
        imagePath = response.imagePath
    }
}
