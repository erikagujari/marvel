//
//  HomeView.swift
//  pokedex
//

import SwiftUI

struct HomeView<VM: HomeViewModelProtocol>: View {
    @Bindable var viewModel: VM
    let imageLoader: any ImageLoaderUseCase

    var body: some View {
        List {
            ForEach(Array(viewModel.characters.enumerated()), id: \.element.id) { index, pokemon in
                NavigationLink(value: Route.detail(id: pokemon.id)) {
                    HomeRowView(pokemon: pokemon, imageLoader: imageLoader)
                }
                .task(id: pokemon.id) {
                    if index == viewModel.characters.count - 1 {
                        await viewModel.willDisplayItemAt(index)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await viewModel.refresh() }
        .task { await viewModel.fetchInitialCharacters() }
        .overlay {
            if viewModel.isLoading && viewModel.characters.isEmpty {
                ProgressView().scaleEffect(1.5)
            }
        }
        .alert(
            viewModel.errorAlert?.title ?? "",
            isPresented: Binding(
                get: { viewModel.errorAlert != nil },
                set: { if !$0 { viewModel.errorAlert = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorAlert?.message ?? "") }
        )
    }
}
