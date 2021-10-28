//
//  FetchCharacterUseCase.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 24/10/21.
//
import Combine
import Foundation

protocol FetchCharacterUseCase {
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacterResponse], MarvelError>
}

struct FetchCharacterUseCaseProvider: FetchCharacterUseCase {
    private let repository: CharacterRepository
    private let authorization: AuthorizedUseCase
    
    init(repository: CharacterRepository, authorization: AuthorizedUseCase) {
        self.repository = repository
        self.authorization = authorization
    }
    
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacterResponse], MarvelError> {
        return authorization.execute()
            .flatMap { authorizationParameters -> AnyPublisher<[MarvelCharacterResponse], MarvelError> in
                let parameters = CharacterService.ListParameters(limit: limit, offset: offset)
                return repository.fetch(parameters: parameters, authorization: authorizationParameters)
                    .flatMap { characters -> AnyPublisher<[MarvelCharacterResponse], MarvelError> in
                        guard characters.isEmpty else {
                            return Just<[MarvelCharacterResponse]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
                        }
                        
                        return Fail<[MarvelCharacterResponse], MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
}
