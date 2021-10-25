//
//  CharacterRepository.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine

protocol CharacterRepository {
    func fetch(parameters: CharacterService.ListParameters) -> AnyPublisher<[MarvelCharacter], MarvelError>
}

struct CharacterRepositoryProvider: CharacterRepository {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func fetch(parameters: CharacterService.ListParameters) -> AnyPublisher<[MarvelCharacter], MarvelError> {
        return httpClient.fetch(CharacterService.list(parameters: parameters), responseType: CharactersResponse.self)
            .map { response in
                return response.data.results
            }.eraseToAnyPublisher()
    }
}
