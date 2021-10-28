//
//  DetailViewModel.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//

import Combine
import UIKit

protocol BaseViewModel {
    var showSpinner: PassthroughSubject<Bool, Never> { get set }
}

protocol DetailViewModelProtocol: BaseViewModel {
    var characterDetail: PassthroughSubject<CharacterDetail, Never> { get set }
    var loadedImage: PassthroughSubject<UIImage, Never> { get set }
    func fetchDetail()
}

final class DetailViewModel {
    private let id: Int
    private let fetchUseCase: FetchCharacterDetailUseCase
    private let imageLoader: ImageLoaderUseCase
    private var cancellables = Set<AnyCancellable>()
    var showSpinner = PassthroughSubject<Bool, Never>()
    var characterDetail = PassthroughSubject<CharacterDetail, Never>()
    var loadedImage = PassthroughSubject<UIImage, Never>()
    
    init(id: Int, fetchUseCase: FetchCharacterDetailUseCase, imageLoader: ImageLoaderUseCase) {
        self.id = id
        self.fetchUseCase = fetchUseCase
        self.imageLoader = imageLoader
    }
    
    private func loadImage(path: String?) {
        guard let path = path else { return }

        imageLoader.fetch(from: path)
            .sink { result in
                if case let .failure = result {
                    //TODO: stop animating and put placeholder into uiimage
                }
            } receiveValue: { [weak self] image in
                self?.loadedImage.send(image)
            }
            .store(in: &cancellables)
    }
}

extension DetailViewModel: DetailViewModelProtocol {
    func fetchDetail() {
        showSpinner.send(true)
        fetchUseCase.execute(id: id)
            .sink { [weak self] result in
                self?.showSpinner.send(false)
            } receiveValue: { [weak self] character in
                self?.characterDetail.send(character)
                self?.loadImage(path: character.imagePath)
            }
            .store(in: &cancellables)
    }
}
