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
        guard let publicKey = bundle.object(forInfoDictionaryKey: "API_PUBLIC_KEY") as? String,
              let privateKey = bundle.object(forInfoDictionaryKey: "API_PRIVATE_KEY") as? String else {
            return Fail<[MarvelCharacter], MarvelError>(error: MarvelError.apiKeyError).eraseToAnyPublisher()
        }
                
        let timestamp = String(Date().timeIntervalSince1970)
        let parameters = CharacterService.ListParameters(limit: limit,
                                                         offset: offset,
                                                         apiKey: publicKey,
                                                         timestamp: timestamp,
                                                         hash: "\(timestamp)\(privateKey)\(publicKey)".toMD5String())
        return repository.fetch(parameters: parameters)
            .flatMap { characters -> AnyPublisher<[MarvelCharacter], MarvelError> in
                guard characters.isEmpty else {
                    return Just<[MarvelCharacter]>(characters).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
                }
                
                return Fail<[MarvelCharacter], MarvelError>(error: MarvelError.serviceError).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
