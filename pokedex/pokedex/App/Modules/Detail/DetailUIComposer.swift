//
//  DetailUIComposer.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//
import CoreData
import SwiftUI

@MainActor
final class DetailUIComposer {
    private init() {}

    static func compose(id: Int, coordinator: AppCoordinator) -> some View {
        let client = URLSessionHTTPClient(session: .shared)
        let repository = PokemonRepositoryProvider(httpClient: client)
        let useCase = FetchPokemonDetailUseCaseProvider(repository: repository)
        let viewModel = DetailViewModel(id: id, fetchUseCase: useCase)
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("feed-store.sqlite")
        let cache: CoreDataFeedStore
        do {
            cache = try CoreDataFeedStore(localURL: storeURL)
        } catch {
            fatalError("Failed to initialize CoreDataFeedStore: \(error)")
        }
        let imageLoader = ImageLoaderProvider(client: client, cache: cache)
        return DetailView(viewModel: viewModel, coordinator: coordinator, imageLoader: imageLoader)
    }
}
