//
//  DetailView.swift
//  pokedex
//

import SwiftUI

struct DetailView<VM: DetailViewModelProtocol>: View {
    @Bindable var viewModel: VM
    let coordinator: AppCoordinator
    let imageLoader: any ImageLoaderUseCase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                CachedAsyncImage(path: viewModel.pokemon?.imageURL, loader: imageLoader)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel(viewModel.pokemon?.name ?? "")
                if let pokemon = viewModel.pokemon {
                    Text(pokemon.name)
                        .font(.system(size: 24, weight: .bold))
                    if let description = pokemon.description {
                        Text(description)
                            .font(.system(size: 16))
                            .italic()
                    }
                    if !pokemon.types.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Types:")
                                .font(.system(size: 14, weight: .bold))
                            ForEach(pokemon.types, id: \.self) { type in
                                Text(type)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView().scaleEffect(1.5)
            }
        }
        .task { await viewModel.fetchDetail() }
        .alert(
            viewModel.errorAlert?.title ?? "",
            isPresented: Binding(
                get: { viewModel.errorAlert != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.errorAlert = nil
                        coordinator.pop()
                    }
                }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorAlert?.message ?? "") }
        )
    }
}
