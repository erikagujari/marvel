//
//  DetailViewController.swift
//  pokedex
//
//  Created by Erik Agujari on 28/10/21.
//

import UIKit

final class DetailViewController: UIViewController {
    private let viewModel: DetailViewModelProtocol
    private let router: DetailRouterProtocol
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var didConfigureContent = false
    private(set) lazy var imageView: UIImageView = {
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

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)

        return label
    }()

    private(set) lazy var descriptionLabel: UILabel = {
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
        bind()
        Task { @MainActor [weak self] in await self?.viewModel.fetchDetail() }
    }

    private func setupView() {
        view.backgroundColor = .white
        setupScrollView()
        contentView.pin(view: mainStackView, leading: 20, trailing: -20)
    }

    private func setupScrollView() {
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

    private func setupContent(pokemon: PokemonDetail) {
        titleLabel.text = pokemon.name
        if let description = pokemon.description {
            descriptionLabel.text = description
            mainStackView.addArrangedSubview(descriptionLabel)
        }
        if !pokemon.types.isEmpty {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 15.0
            let label = UILabel()
            label.font = UIFont.boldSystemFont(ofSize: 14)
            label.text = "Types:"
            stackView.addArrangedSubview(label)
            pokemon.types.forEach { type in
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 14)
                label.text = type
                label.numberOfLines = 0
                stackView.addArrangedSubview(label)
            }
            mainStackView.addArrangedSubview(stackView)
        }
    }

    @MainActor
    private func bind() {
        withObservationTracking {
            _ = viewModel.pokemon
            _ = viewModel.image
            _ = viewModel.isLoading
            _ = viewModel.errorAlert
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.render()
                self.bind()
            }
        }
        render()
    }

    @MainActor
    private func render() {
        viewModel.isLoading ? view.showSpinner() : view.dismissSpinner()
        if !didConfigureContent, let pokemon = viewModel.pokemon {
            setupContent(pokemon: pokemon)
            didConfigureContent = true
        }
        if let image = viewModel.image {
            imageView.image = image
            imageView.dismissSpinner()
        }
        if let alert = viewModel.errorAlert {
            router.showError(title: alert.title, message: alert.message)
            viewModel.errorAlert = nil
        }
    }
}
