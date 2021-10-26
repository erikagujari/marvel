//
//  Helpers.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
@testable import marvel_heroes

func anyMarvelCharacterList() -> [MarvelCharacter] {
    return [MarvelCharacter(id: 0, name: "", description: "", modified: "", thumbnail: Thumbnail(path: "", fileExtension: ""))]
}

struct FetchCharacterUseCaseStub: FetchCharacterUseCase {
    let result: AnyPublisher<[MarvelCharacter], MarvelError>
    
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError> {
        return result
    }
}
