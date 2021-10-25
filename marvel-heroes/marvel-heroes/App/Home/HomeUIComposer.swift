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
        let viewModel = HomeViewModelProvider(fetchCharactersUseCase: fetchUseCase, limitRequest: limitRequest)
        return UINavigationController(rootViewController: HomeViewController(viewModel: viewModel))
    }
}
