//
//  Helpers.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
import UIKit
@testable import marvel_heroes

func anyMarvelCharacterList() -> [MarvelCharacter] {
    return [MarvelCharacter(id: 0, name: "", description: "", modified: "", thumbnail: Thumbnail(path: "", fileExtension: ""))]
}

struct FetchCharacterUseCaseStub: FetchCharacterUseCase {
    private let result: AnyPublisher<[MarvelCharacter], MarvelError>
    private let delay: Double?
    
    init(result: AnyPublisher<[MarvelCharacter], MarvelError>, delay: Double? = nil) {
        self.result = result
        self.delay = delay
    }
    
    func execute(limit: Int, offset: Int) -> AnyPublisher<[MarvelCharacter], MarvelError> {
        guard let delay = delay else {
            return result
        }

        return result.delay(for: RunLoop.SchedulerTimeType.Stride(delay), scheduler: RunLoop.main).eraseToAnyPublisher()
    }
}

struct ImageLoaderUseCaseStub: ImageLoaderUseCase {
    func fetch(from path: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        completion(.success(UIImage()))
    }
    
    func cancel() { }
}
