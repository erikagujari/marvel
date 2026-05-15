//
//  HomeRowView.swift
//  pokedex
//

import SwiftUI

struct HomeRowView: View {
    let pokemon: Pokemon
    let imageLoader: any ImageLoaderUseCase

    var body: some View {
        HStack(spacing: 20) {
            CachedAsyncImage(path: pokemon.imageURL, loader: imageLoader)
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
            Text(pokemon.name)
                .font(.system(size: 18, weight: .bold))
            Spacer()
        }
        .padding(.vertical, 10)
    }
}
