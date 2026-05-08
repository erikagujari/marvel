//
//  Helpers.swift
//  pokedexTests
//
//  Created by Erik Agujari on 25/10/21.
//
import Combine
@testable import pokedex
import UIKit

func anyPokemonList(ids: [Int] = [0]) -> [Pokemon] {
    return ids.map { id in
        Pokemon(id: id, name: "name-\(id)", imageURL: "https://any-image/\(id).png")
    }
}

func anyPokemonDetail(id: Int = 0) -> PokemonDetail {
    return PokemonDetail(id: id, name: "name-\(id)", imageURL: "https://any-image/\(id).png", types: ["grass"], description: "Any description")
}

class FetchPokemonUseCaseStub: FetchPokemonUseCase {
    private let firstLoadResult: AnyPublisher<[Pokemon], APIError>
    private let nextLoadResult: AnyPublisher<[Pokemon], APIError>
    private let delay: Double?
    private var executeCount = 0

    init(firstLoadResult: AnyPublisher<[Pokemon], APIError>,
         delay: Double? = nil,
         nextLoadResult: AnyPublisher<[Pokemon], APIError> = Just(anyPokemonList(ids: [3, 4, 5])).setFailureType(to: APIError.self).eraseToAnyPublisher()) {
        self.firstLoadResult = firstLoadResult
        self.delay = delay
        self.nextLoadResult = nextLoadResult
    }

    func execute(limit: Int, offset: Int) -> AnyPublisher<[Pokemon], APIError> {
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
    let result: AnyPublisher<UIImage, APIError>

    func fetch(from path: String) -> AnyPublisher<UIImage, APIError> {
        return result
    }
}

struct PokemonRepositoryStub: PokemonRepository {
    let listResult: AnyPublisher<[Pokemon], APIError>
    let detailResult: AnyPublisher<PokemonDetail, APIError>

    func fetch(offset: Int, limit: Int) -> AnyPublisher<[Pokemon], APIError> {
        return listResult
    }

    func fetchDetail(id: Int) -> AnyPublisher<PokemonDetail, APIError> {
        return detailResult
    }
}
