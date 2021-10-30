//
//  FetchCharacterDetailUseCase.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//
import Combine

protocol FetchCharacterDetailUseCase {
    func execute(id: Int) -> AnyPublisher<CharacterDetail, MarvelError>
}

struct FetchCharacterDetailUseCaseProvider: FetchCharacterDetailUseCase {
    private let repository: CharacterRepository
    private let authorization: AuthorizedUseCase
    
    init(repository: CharacterRepository, authorization: AuthorizedUseCase) {
        self.repository = repository
        self.authorization = authorization
    }
    
    func execute(id: Int) -> AnyPublisher<CharacterDetail, MarvelError> {        
        return authorization.execute()
            .flatMap { authorizationParameters in
                return repository.fetchDetail(id: id, authorization: authorizationParameters)
                    .compactMap { response in
                        return CharacterDetail(from: response.data.results[0])
                    }
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
}
