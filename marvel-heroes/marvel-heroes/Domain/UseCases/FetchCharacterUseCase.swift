//
//  FetchCharacterUseCase.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 24/10/21.
//
import Combine
import Foundation

protocol FetchCharacterUseCase {
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError>
}

struct FetchCharacterUseCaseProvider: FetchCharacterUseCase {
    private let repository: CharacterRepository
    private let bundle: Bundle
    
    init(repository: CharacterRepository, bundle: Bundle) {
        self.repository = repository
        self.bundle = bundle
    }
    
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError> {
        guard let apiKey = bundle.object(forInfoDictionaryKey: "API_KEY") as? String else {
            return Fail<[MarvelCharacter], MarvelError>(error: MarvelError.apiKeyError).eraseToAnyPublisher()
        }
                
        return repository.fetch(limit: limit, offset: offset, apiKey: apiKey)
            .flatMap { characters -> AnyPublisher<[MarvelCharacter], MarvelError> in
                guard characters.isEmpty else {
                    return Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
                }
                
                return Fail<[MarvelCharacter], MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
