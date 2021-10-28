//
//  CharacterRepository.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine

protocol CharacterRepository {
    func fetch(parameters: CharacterService.ListParameters, authorization: CharacterService.AuthorizationParameters) -> AnyPublisher<[MarvelCharacterResponse], MarvelError>
    func fetchDetail(id: Int, authorization: CharacterService.AuthorizationParameters) -> AnyPublisher<CharacterDetailResponse, MarvelError>
}

struct CharacterRepositoryProvider: CharacterRepository {
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func fetch(parameters: CharacterService.ListParameters, authorization: CharacterService.AuthorizationParameters) -> AnyPublisher<[MarvelCharacterResponse], MarvelError> {
        return httpClient.fetch(CharacterService.list(parameters: parameters, authorization: authorization), responseType: CharactersResponse.self)
            .map { response in
                return response.data.results
            }.eraseToAnyPublisher()
    }
    
    func fetchDetail(id: Int, authorization: CharacterService.AuthorizationParameters) -> AnyPublisher<CharacterDetailResponse, MarvelError> {
        return httpClient.fetch(CharacterService.detail(id: id, authorization: authorization), responseType: CharacterDetailResponse.self)
    }
}
