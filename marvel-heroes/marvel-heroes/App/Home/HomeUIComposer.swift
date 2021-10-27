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
        let imageLoader = ImageLoaderProvider(client: URLSessionHTTPClient(session: .shared))
        let viewModel = HomeViewModelProvider(fetchCharactersUseCase: fetchUseCase,
                                              limitRequest: limitRequest,
                                              imageLoader: imageLoader)
        let navigation = UINavigationController(rootViewController: HomeViewController(viewModel: viewModel))
        navigation.navigationBar.prefersLargeTitles = true
        
        return navigation
    }
}
