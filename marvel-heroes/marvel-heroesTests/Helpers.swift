//
//  Helpers.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
import UIKit
@testable import marvel_heroes

func anyMarvelCharacterList(ids: [Int] = [0]) -> [MarvelCharacter] {
    return ids.map { id in
        MarvelCharacter(id: id, name: "", description: "", modified: "", thumbnail: Thumbnail(path: "", fileExtension: ""))
    }
}

class FetchCharacterUseCaseStub: FetchCharacterUseCase {
    private let firstLoadResult: AnyPublisher<[MarvelCharacter], MarvelError>
    private let nextLoadResult: AnyPublisher<[MarvelCharacter], MarvelError>
    private let delay: Double?
    private var executeCount = 0
    
    init(firstLoadResult: AnyPublisher<[MarvelCharacter], MarvelError>,
         delay: Double? = nil,
         nextLoadResult: AnyPublisher<[MarvelCharacter], MarvelError> = Just(anyMarvelCharacterList(ids: [3,4,5])).setFailureType(to: MarvelError.self).eraseToAnyPublisher()) {
        self.firstLoadResult = firstLoadResult
        self.delay = delay
        self.nextLoadResult = nextLoadResult
    }
    
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError> {
        guard executeCount == 0 else {
            return nextLoadResult
        }
        
        executeCount += 1
        guard let delay = delay else {
            return firstLoadResult
        }

        return firstLoadResult.delay(for: RunLoop.SchedulerTimeType.Stride(delay), scheduler: RunLoop.main).eraseToAnyPublisher()
    }
}

struct ImageLoaderUseCaseStub: ImageLoaderUseCase {
    let result: AnyPublisher<UIImage, MarvelError>
    
    func fetch(from path: String) -> AnyPublisher<UIImage, MarvelError> {
        return result
    }
}
