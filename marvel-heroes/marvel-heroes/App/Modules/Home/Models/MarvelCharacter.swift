//
//  MarvelCharacter.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//

struct MarvelCharacter: Equatable {
    let id: Int
    let name: String
    let description: String?
    let imagePath: String?
    
    init?(from character: MarvelCharacterResponse) {
        guard let id = character.id,
              let name = character.name
        else { return nil }
        
        self.id = id
        self.name = name
        description = character.description
        imagePath = character.imagePath
    }
}
