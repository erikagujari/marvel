//
//  DetailUIComposer.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//

import UIKit

final class DetailUIComposer {
    private init() {}
    
    static func compose(id: Int) -> UIViewController {
        let router = DetailRouter()
        let repository = CharacterRepositoryProvider(httpClient: URLSessionHTTPClient(session: .shared))
        let useCase = FetchCharacterDetailUseCaseProvider(repository: repository, authorization: AuthorizedUseCaseProvider(bundle: .main))
        let viewModel = DetailViewModel(id: id, fetchUseCase: useCase)
        let viewController = DetailViewController(viewModel: viewModel, router: router)
        router.viewController = viewController
        
        return viewController
    }
}
