//
//  CachedAsyncImage.swift
//  pokedex
//

import SwiftUI
import UIKit

struct CachedAsyncImage: View {
    let path: String?
    let loader: any ImageLoaderUseCase

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                ProgressView()
            }
        }
        .task(id: path) {
            image = nil
            guard let path else { return }
            do {
                image = try await loader.fetch(from: path)
            } catch is CancellationError {
                return
            } catch {
                image = UIImage(named: "wifi")
            }
        }
    }
}
