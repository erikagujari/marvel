//
//  CharacterRepository.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine

protocol CharacterRepository {
    func fetch(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError>
}

struct CharacterRepositoryProvider: CharacterRepository {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func fetch(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError> {
        return httpClient.fetch(CharacterService.list(limit: limit, offset: offset), responseType: CharactersResponse.self)
            .map { response in
                return response.data.results
            }.eraseToAnyPublisher()
    }
}
