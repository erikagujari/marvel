//
//  MarvelCharacterResponse.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//

struct CharactersResponse: Decodable {
    let data: CharactersResponseData
}

struct CharactersResponseData: Decodable {
    let results: [MarvelCharacterResponse]
}

struct MarvelCharacterResponse: Decodable {
    let id: Int?
    let name: String?
    let description: String?
    let modified: String?
    let thumbnail: ThumbnailResponse
    let comics: ComicsResponse?
}

struct ComicsResponse: Decodable {
    let items: [ComicResponse]
}

struct ComicResponse: Decodable {
    let name: String
}

struct ThumbnailResponse: Decodable {
    let path: String?
    let fileExtension: String?
    
    private enum CodingKeys: String, CodingKey {
        case path
        case fileExtension = "extension"
    }
}
