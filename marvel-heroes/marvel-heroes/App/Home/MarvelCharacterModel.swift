//
//  MarvelCharacterModel.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//

struct MarvelCharacterModel {
    let id: Int
    let name: String
    let description: String?
    let imagePath: String?
    
    init?(from character: MarvelCharacter) {
        guard let id = character.id,
              let name = character.name
        else { return nil }
        
        self.id = id
        self.name = name
        self.description = character.description
        if let path = character.thumbnail.path,
           let fileExtension = character.thumbnail.fileExtension {
            imagePath = "\(path).\(fileExtension)"
        } else {
            imagePath = nil
        }
    }
}
