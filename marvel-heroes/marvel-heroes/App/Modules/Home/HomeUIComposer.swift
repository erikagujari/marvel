//
//  HomeUIComposer.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//

import CoreData
import UIKit

final class HomeUIComposer {
    private init() {}
    
    static func compose(limitRequest: Int) -> UIViewController {
        let cache = try! CoreDataFeedStore(localURL: NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("feed-store.sqlite"))
        let imageLoader = ImageLoaderProvider(client: URLSessionHTTPClient(session: .shared), cache: cache)
        let useCase = FetchCharacterUseCaseProvider(repository: CharacterRepositoryProvider(httpClient: URLSessionHTTPClient(session: .shared)),
                                                    authorization: AuthorizedUseCaseProvider(bundle: .main))
        let viewModel = HomeViewModel(fetchCharactersUseCase: useCase,
                                              limitRequest: limitRequest,
                                              imageLoader: imageLoader)
        let router = HomeRouter()
        let viewController = HomeViewController(viewModel: viewModel, router: router)
        let navigation = UINavigationController(rootViewController: viewController)
        router.viewController = viewController
        
        navigation.navigationBar.prefersLargeTitles = true
        
        return navigation
    }
}
