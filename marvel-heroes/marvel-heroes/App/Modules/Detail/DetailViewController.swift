//
//  DetailViewController.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//

import UIKit

final class DetailViewController: UIViewController {
    private let viewModel: DetailViewModelProtocol
    private let router: DetailRouterProtocol
    
    init(viewModel: DetailViewModelProtocol, router: DetailRouterProtocol) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupBinding()
        viewModel.fetchDetail()
    }
    
    private func setupView() {
        view.backgroundColor = .white
    }
    
    private func setupBinding() {
        
    }
}
