//
//  DetailViewController.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//
import Combine
import UIKit

final class DetailViewController: UIViewController {
    private let viewModel: DetailViewModelProtocol
    private let router: DetailRouterProtocol
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var cancellables = Set<AnyCancellable>()
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: view.frame.height / 3)
        ])
        imageView.layer.cornerRadius = 10.0
        imageView.clipsToBounds = true
        imageView.showSpinner()
        return imageView
    }()
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageView, titleLabel])
        stackView.axis = .vertical
        stackView.spacing = 25
        
        return stackView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.italicSystemFont(ofSize: 16)
        
        return label
    }()
    
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
        setupScrollView()
        contentView.pin(view: mainStackView, leading: 20, trailing: -20)
    }
    
    private func setupScrollView(){
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        contentView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
    }
    
    private func setupContent(character: CharacterDetail) {
        titleLabel.text = character.name
        if let description = character.description {
            descriptionLabel.text = description
            mainStackView.addArrangedSubview(descriptionLabel)
        }
        if let comics = character.comics {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 15.0
            let label = UILabel()
            label.font = UIFont.boldSystemFont(ofSize: 14)
            label.text = "Comics:"
            stackView.addArrangedSubview(label)
            comics.forEach { comic in
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 14)
                label.text = comic
                stackView.addArrangedSubview(label)
            }
            mainStackView.addArrangedSubview(stackView)
        }
    }
    
    private func setupBinding() {
        viewModel.showSpinner
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] show in
                show ? self?.view.showSpinner() : self?.view.dismissSpinner()
            })
            .store(in: &cancellables)
        
        viewModel.characterDetail
            .receive(on: DispatchQueue.main)
            .sink { [weak self] character in
                self?.setupContent(character: character)
            }
            .store(in: &cancellables)
    }
}
