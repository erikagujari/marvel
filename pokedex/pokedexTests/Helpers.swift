//
//  Helpers.swift
//  pokedexTests
//
//  Created by Erik Agujari on 25/10/21.
//
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

@MainActor
func waitFor(timeout: Duration = .seconds(1), _ predicate: @escaping @MainActor () -> Bool) async {
    let deadline = ContinuousClock.now + timeout
    while !predicate() && ContinuousClock.now < deadline {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(10))
    }
}

final class FetchPokemonUseCaseStub: FetchPokemonUseCase, @unchecked Sendable {
    private let firstLoadResult: Result<[Pokemon], APIError>
    private let nextLoadResult: Result<[Pokemon], APIError>
    private let delay: Duration?
    private var executeCount = 0

    init(firstLoadResult: Result<[Pokemon], APIError>,
         delay: Duration? = nil,
         nextLoadResult: Result<[Pokemon], APIError> = .success(anyPokemonList(ids: [3, 4, 5]))) {
        self.firstLoadResult = firstLoadResult
        self.delay = delay
        self.nextLoadResult = nextLoadResult
    }

    func execute(limit: Int, offset: Int) async throws -> [Pokemon] {
        let isFirst = executeCount == 0
        executeCount += 1
        if isFirst, let delay = delay {
            try await Task.sleep(for: delay)
        }
        return try (isFirst ? firstLoadResult : nextLoadResult).get()
    }
}

struct ImageLoaderUseCaseStub: ImageLoaderUseCase {
    let result: Result<UIImage, APIError>
    let delay: Duration?

    init(result: Result<UIImage, APIError>, delay: Duration? = nil) {
        self.result = result
        self.delay = delay
    }

    func fetch(from path: String) async throws -> UIImage {
        if let delay = delay {
            try await Task.sleep(for: delay)
        }
        return try result.get()
    }
}

struct PokemonRepositoryStub: PokemonRepository {
    let listResult: Result<[Pokemon], APIError>
    let detailResult: Result<PokemonDetail, APIError>

    func fetch(offset: Int, limit: Int) async throws -> [Pokemon] {
        try listResult.get()
    }

    func fetchDetail(id: Int) async throws -> PokemonDetail {
        try detailResult.get()
    }
}
