//
//  DetailViewModel.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//

import Combine

protocol BaseViewModel {
    var showSpinner: PassthroughSubject<Bool, Never> { get set }
}

protocol DetailViewModelProtocol: BaseViewModel {
    func fetchDetail()
}

final class DetailViewModel {
    private let id: Int
    private let fetchUseCase: FetchCharacterDetailUseCase
    private var cancellables = Set<AnyCancellable>()
    var showSpinner = PassthroughSubject<Bool, Never>()
    
    init(id: Int, fetchUseCase: FetchCharacterDetailUseCase) {
        self.id = id
        self.fetchUseCase = fetchUseCase
    }
}

extension DetailViewModel: DetailViewModelProtocol {
    func fetchDetail() {
        showSpinner.send(true)
        fetchUseCase.execute(id: id)
            .sink { [weak self] result in
                self?.showSpinner.send(false)
            } receiveValue: { characterResponse in
                print(characterResponse)
            }
            .store(in: &cancellables)
    }
}
