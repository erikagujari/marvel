//
//  HomeViewController.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//

import UIKit

final class HomeViewController: UITableViewController {
    private let viewModel: HomeViewModelProtocol
    private let router: HomeRouterProtocol

    init(viewModel: HomeViewModelProtocol, router: HomeRouterProtocol) {
        self.viewModel = viewModel
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        bind()
        Task { @MainActor [weak self] in
            await self?.viewModel.fetchInitialCharacters()
        }
    }

    @MainActor
    private func bind() {
        withObservationTracking {
            _ = viewModel.characters
            _ = viewModel.title
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
        title = viewModel.title
        tableView.reloadData()
        viewModel.isLoading ? view.showSpinner() : view.dismissSpinner()
        if let alert = viewModel.errorAlert {
            router.showError(title: alert.title, message: alert.message)
            viewModel.errorAlert = nil
        }
    }

    private func setupTableView() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.register(HomeCell.self, forCellReuseIdentifier: HomeCell.description())
    }

    @objc private func refresh() {
        refreshControl?.endRefreshing()
        Task { @MainActor [weak self] in await self?.viewModel.refresh() }
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.characters.count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeCell.description(), for: indexPath) as? HomeCell else {
            return UITableViewCell()
        }

        let model = viewModel.cellModel(for: indexPath.row, imageAction: cell.update)
        cell.configure(model: model)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension HomeViewController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        Task { @MainActor [weak self] in await self?.viewModel.willDisplayItemAt(indexPath.row) }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        router.showDetail(id: viewModel.idForRowAt(indexPath.row))
    }
}
