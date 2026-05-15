//
//  HomeUIComposer.swift
//  pokedex
//
//  Created by Erik Agujari on 25/10/21.
//

import CoreData
import SwiftUI

@MainActor
final class HomeUIComposer {
    private init() {}

    static func compose(limitRequest: Int) -> some View {
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
        let viewModel = HomeViewModel(fetchPokemonUseCase: useCase, limitRequest: limitRequest)
        return HomeView(viewModel: viewModel, imageLoader: imageLoader)
    }
}
