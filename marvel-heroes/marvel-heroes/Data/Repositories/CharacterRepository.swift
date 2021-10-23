//
//  CharacterRepository.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine

protocol CharacterRepository {
    func fetch(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], Error>
}

struct CharacterRepositoryProvider: CharacterRepository {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func fetch(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], Error> {
        return httpClient.fetch(CharacterService.list(limit: limit, offset: offset), responseType: [MarvelCharacter].self)
    }
}
