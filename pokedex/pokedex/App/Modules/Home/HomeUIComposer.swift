//
//  HomeUIComposer.swift
//  pokedex
//
//  Created by Erik Agujari on 25/10/21.
//

import CoreData
import UIKit

@MainActor
final class HomeUIComposer {
    private init() {}

    static func compose(limitRequest: Int) -> UIViewController {
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("feed-store.sqlite")
        let cache: CoreDataFeedStore
        do {
            cache = try CoreDataFeedStore(localURL: storeURL)
        } catch {
            fatalError("Failed to initialize CoreDataFeedStore: \(error)")
        }
        let imageLoader = ImageLoaderProvider(client: URLSessionHTTPClient(session: .shared), cache: cache)
        let useCase = FetchPokemonUseCaseProvider(repository: PokemonRepositoryProvider(httpClient: URLSessionHTTPClient(session: .shared)))
        let viewModel = HomeViewModel(fetchPokemonUseCase: useCase,
                                      limitRequest: limitRequest,
                                      imageLoader: imageLoader)
        let router = HomeRouter()
        let viewController = HomeViewController(viewModel: viewModel, router: router)
        let navigation = UINavigationController(rootViewController: viewController)
        router.viewController = viewController

        navigation.navigationBar.prefersLargeTitles = true

        return navigation
    }
}
