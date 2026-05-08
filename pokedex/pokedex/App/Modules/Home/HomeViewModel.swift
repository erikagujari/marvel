//
//  HomeViewModel.swift
//  pokedex
//
//  Created by Erik Agujari on 25/10/21.
//

import UIKit

@MainActor
protocol HomeViewModelProtocol: BaseViewModel {
    var characters: [Pokemon] { get }
    var title: String { get }
    func fetchInitialCharacters() async
    func cellModel(for index: Int, imageAction: @escaping @MainActor (UIImage) -> Void) -> HomeCellModel
    func willDisplayItemAt(_ index: Int) async
    func refresh() async
    func idForRowAt(_ index: Int) -> Int
}

@Observable @MainActor
final class HomeViewModel: HomeViewModelProtocol {
    @ObservationIgnored private let fetchPokemonUseCase: FetchPokemonUseCase
    @ObservationIgnored private let limitRequest: Int
    @ObservationIgnored private let imageLoader: ImageLoaderUseCase
    @ObservationIgnored private var imageTasks: [Int: Task<Void, Never>] = [:]

    private(set) var characters: [Pokemon] = []
    private(set) var title: String = "Pokédex"
    var isLoading: Bool = false
    var errorAlert: ErrorAlert?

    init(fetchPokemonUseCase: FetchPokemonUseCase, limitRequest: Int, imageLoader: ImageLoaderUseCase) {
        self.fetchPokemonUseCase = fetchPokemonUseCase
        self.limitRequest = limitRequest
        self.imageLoader = imageLoader
    }

    deinit {
        imageTasks.values.forEach { $0.cancel() }
    }

    func fetchInitialCharacters() async {
        await loadCharacters(offset: 0)
    }

    func refresh() async {
        await loadCharacters(offset: characters.count)
    }

    func willDisplayItemAt(_ index: Int) async {
        guard characters.indices.contains(index),
              let last = characters.last,
              characters[index] == last else { return }
        await loadCharacters(offset: characters.count)
    }

    func idForRowAt(_ index: Int) -> Int {
        guard characters.indices.contains(index) else { return -1 }
        return characters[index].id
    }

    func cellModel(for index: Int, imageAction: @escaping @MainActor (UIImage) -> Void) -> HomeCellModel {
        guard characters.indices.contains(index) else {
            return HomeCellModel(title: "", description: nil, cancelAction: nil)
        }
        let model = characters[index]
        guard let path = model.imageURL else {
            return HomeCellModel(title: model.name, description: nil, cancelAction: nil)
        }

        startImageLoad(id: model.id, path: path, imageAction: imageAction)
        return HomeCellModel(title: model.name, description: nil, cancelAction: { [weak self] in
            self?.imageTasks[model.id]?.cancel()
            self?.imageTasks[model.id] = nil
        })
    }

    private func startImageLoad(id: Int, path: String, imageAction: @escaping @MainActor (UIImage) -> Void) {
        imageTasks[id]?.cancel()
        let loader = imageLoader
        imageTasks[id] = Task { @MainActor [weak self] in
            defer { self?.imageTasks[id] = nil }
            do {
                let image = try await loader.fetch(from: path)
                try Task.checkCancellation()
                imageAction(image)
            } catch is CancellationError {
                return
            } catch {
                if let fallback = UIImage(named: "wifi") {
                    imageAction(fallback)
                }
            }
        }
    }

    private func loadCharacters(offset: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let new = try await fetchPokemonUseCase.execute(limit: limitRequest, offset: offset)
            characters += new
        } catch let error as APIError {
            errorAlert = ErrorAlert(title: Constants.errorTitle, message: error.description)
        } catch {
            errorAlert = ErrorAlert(title: Constants.errorTitle, message: APIError.serviceError.description)
        }
    }
}

private extension HomeViewModel {
    enum Constants {
        static let errorTitle = "!Oops, we had an error!"
    }
}
