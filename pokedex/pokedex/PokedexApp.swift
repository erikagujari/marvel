//
//  PokedexApp.swift
//  pokedex
//

import CoreData
import SwiftUI

@main
struct PokedexApp: App {
    @State private var coordinator = AppCoordinator()
    private let httpClient: any HTTPClient
    private let imageLoader: any ImageLoaderUseCase

    init() {
        let client = URLSessionHTTPClient(session: .shared)
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("feed-store.sqlite")
        let cache: CoreDataFeedStore
        do {
            cache = try CoreDataFeedStore(localURL: storeURL)
        } catch {
            fatalError("Failed to initialize CoreDataFeedStore: \(error)")
        }
        self.httpClient = client
        self.imageLoader = ImageLoaderProvider(client: client, cache: cache)
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                coordinator: coordinator,
                httpClient: httpClient,
                imageLoader: imageLoader
            )
        }
    }
}

private struct RootView: View {
    @Bindable var coordinator: AppCoordinator
    let httpClient: any HTTPClient
    let imageLoader: any ImageLoaderUseCase

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeUIComposer.compose(
                limitRequest: 20,
                httpClient: httpClient,
                imageLoader: imageLoader
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .detail(let id):
                    DetailUIComposer.compose(
                        id: id,
                        coordinator: coordinator,
                        httpClient: httpClient,
                        imageLoader: imageLoader
                    )
                }
            }
        }
    }
}
