//
//  HomeUIComposer.swift
//  pokedex
//
//  Created by Erik Agujari on 25/10/21.
//

import SwiftUI

@MainActor
final class HomeUIComposer {
    private init() {}

    static func compose(
        limitRequest: Int,
        httpClient: any HTTPClient,
        imageLoader: any ImageLoaderUseCase
    ) -> some View {
        let repository = PokemonRepositoryProvider(httpClient: httpClient)
        let useCase = FetchPokemonUseCaseProvider(repository: repository)
        let viewModel = HomeViewModel(fetchPokemonUseCase: useCase, limitRequest: limitRequest)
        return HomeView(viewModel: viewModel, imageLoader: imageLoader)
    }
}
