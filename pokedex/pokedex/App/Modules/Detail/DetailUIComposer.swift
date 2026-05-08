//
//  DetailUIComposer.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//
import CoreData
import UIKit

@MainActor
final class DetailUIComposer {
    private init() {}

    static func compose(id: Int) -> UIViewController {
        let router = DetailRouter()
        let client = URLSessionHTTPClient(session: .shared)
        let repository = PokemonRepositoryProvider(httpClient: client)
        let useCase = FetchPokemonDetailUseCaseProvider(repository: repository)
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("feed-store.sqlite")
        let cache: CoreDataFeedStore
        do {
            cache = try CoreDataFeedStore(localURL: storeURL)
        } catch {
            fatalError("Failed to initialize CoreDataFeedStore: \(error)")
        }
        let imageLoader = ImageLoaderProvider(client: client, cache: cache)
        let viewModel = DetailViewModel(id: id, fetchUseCase: useCase, imageLoader: imageLoader)
        let viewController = DetailViewController(viewModel: viewModel, router: router)
        router.viewController = viewController

        return viewController
    }
}
