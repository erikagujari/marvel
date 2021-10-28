//
//  CharacterDetailResponse.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//

struct CharacterDetailResponse: Decodable {
    let data: CharacterDetailResponseData
}

struct CharacterDetailResponseData: Decodable {
    let results: [MarvelCharacterResponse]
}
