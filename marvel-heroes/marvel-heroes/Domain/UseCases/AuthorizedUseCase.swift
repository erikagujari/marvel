//
//  AuthorizedUseCase.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//
import Foundation
import Combine

protocol AuthorizedUseCase {
    func execute() -> AnyPublisher<CharacterService.AuthorizationParameters, MarvelError>
}

struct AuthorizedUseCaseProvider: AuthorizedUseCase {
    private let bundle: Bundle
    
    init(bundle: Bundle) {
        self.bundle = bundle
    }
    
    func execute() -> AnyPublisher<CharacterService.AuthorizationParameters, MarvelError> {
        guard let publicKey = bundle.object(forInfoDictionaryKey: "API_PUBLIC_KEY") as? String,
              let privateKey = bundle.object(forInfoDictionaryKey: "API_PRIVATE_KEY") as? String else {
                  return Fail(error: MarvelError.apiKeyError).eraseToAnyPublisher()
              }
        
        let timestamp = String(Date().timeIntervalSince1970)
        let authorization = CharacterService.AuthorizationParameters(apiKey: publicKey, timestamp: timestamp, hash: "\(timestamp)\(privateKey)\(publicKey)".toMD5String())
        return Just(authorization).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
    }
}

