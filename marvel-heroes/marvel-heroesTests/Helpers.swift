//
//  Helpers.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
import UIKit
@testable import marvel_heroes

func anyMarvelCharacterList(ids: [Int] = [0]) -> [MarvelCharacterResponse] {
    return ids.map { id in
        MarvelCharacterResponse(id: id, name: "", description: "", modified: "", thumbnail: ThumbnailResponse(path: "", fileExtension: ""), comics: nil)
    }
}

class FetchCharacterUseCaseStub: FetchCharacterUseCase {
    private let firstLoadResult: AnyPublisher<[MarvelCharacterResponse], MarvelError>
    private let nextLoadResult: AnyPublisher<[MarvelCharacterResponse], MarvelError>
    private let delay: Double?
    private var executeCount = 0
    
    init(firstLoadResult: AnyPublisher<[MarvelCharacterResponse], MarvelError>,
         delay: Double? = nil,
         nextLoadResult: AnyPublisher<[MarvelCharacterResponse], MarvelError> = Just(anyMarvelCharacterList(ids: [3,4,5])).setFailureType(to: MarvelError.self).eraseToAnyPublisher()) {
        self.firstLoadResult = firstLoadResult
        self.delay = delay
        self.nextLoadResult = nextLoadResult
    }
    
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacterResponse], MarvelError> {
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
