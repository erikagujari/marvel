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
        let viewModel = HomeViewModelProvider(fetchCharactersUseCase: fetchUseCase, limitRequest: limitRequest, imageLoader: ImageLoaderProvider(session: .shared))
        let navigation = UINavigationController(rootViewController: HomeViewController(viewModel: viewModel))
        navigation.navigationBar.prefersLargeTitles = true
        
        return navigation
    }
}
