//
//  FetchCharacterUseCase.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 24/10/21.
//
import Combine

protocol FetchCharacterUseCase {
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError>
}

struct FetchCharacterUseCaseProvider: FetchCharacterUseCase {
    private let repository: CharacterRepository
    
    init(repository: CharacterRepository) {
        self.repository = repository
    }
    
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError> {
        return repository.fetch(limit: limit, offset: offset)
            .flatMap { characters -> AnyPublisher<[MarvelCharacter], MarvelError> in
                guard characters.isEmpty else {
                    return Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
                }
                
                return Fail<[MarvelCharacter], MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
