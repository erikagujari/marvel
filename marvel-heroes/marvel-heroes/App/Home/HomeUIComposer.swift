//
//  HomeUIComposer.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//

import UIKit

final class HomeUIComposer {
    private init() {}
    
    static func compose(fetchUseCase: FetchCharacterUseCase, limitRequest: Int) -> UIViewController {
        let imageLoader = ImageLoaderProvider(client: URLSessionHTTPClient(session: .shared), cache: NSCache())
        let viewModel = HomeViewModel(fetchCharactersUseCase: fetchUseCase,
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
