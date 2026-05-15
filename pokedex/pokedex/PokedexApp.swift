//
//  PokedexApp.swift
//  pokedex
//

import SwiftUI

@main
struct PokedexApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
        }
    }
}

private struct RootView: View {
    @Bindable var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeUIComposer.compose(limitRequest: 20)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .detail(let id):
                        DetailUIComposer.compose(id: id, coordinator: coordinator)
                    }
                }
        }
    }
}
