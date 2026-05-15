//
//  DetailUIComposer.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//
import SwiftUI

@MainActor
final class DetailUIComposer {
    private init() {}

    static func compose(
        id: Int,
        coordinator: AppCoordinator,
        httpClient: any HTTPClient,
        imageLoader: any ImageLoaderUseCase
    ) -> some View {
        let repository = PokemonRepositoryProvider(httpClient: httpClient)
        let useCase = FetchPokemonDetailUseCaseProvider(repository: repository)
        let viewModel = DetailViewModel(id: id, fetchUseCase: useCase)
        return DetailView(viewModel: viewModel, coordinator: coordinator, imageLoader: imageLoader)
    }
}
