//
//  DetailUIComposer.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//
import CoreData
import UIKit

final class DetailUIComposer {
    private init() {}
    
    static func compose(id: Int) -> UIViewController {
        let router = DetailRouter()
        let client = URLSessionHTTPClient(session: .shared)
        let repository = CharacterRepositoryProvider(httpClient: client)
        let useCase = FetchCharacterDetailUseCaseProvider(repository: repository, authorization: AuthorizedUseCaseProvider(bundle: .main))
        let cache = try! CoreDataFeedStore(localURL: NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("feed-store.sqlite"))
        let imageLoader = ImageLoaderProvider(client: client, cache: cache)
        let viewModel = DetailViewModel(id: id, fetchUseCase: useCase, imageLoader: imageLoader)
        let viewController = DetailViewController(viewModel: viewModel, router: router)
        router.viewController = viewController
        
        return viewController
    }
}
