//
//  HomeViewController.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine
import UIKit

final class HomeViewController: UITableViewController {
    private let viewModel: HomeViewModelProtocol
    private let router: HomeRouterProtocol
    private var cancellables = Set<AnyCancellable>()
    
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
        
        setupBindings()
        setupTableView()
        viewModel.fetchInitialCharacters()
    }
    
    private func setupBindings() {
        viewModel.characters
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
        }.store(in: &cancellables)
        
        viewModel.showSpinner
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] show in
                show ? self?.view.showSpinner() : self?.view.dismissSpinner()
            })
            .store(in: &cancellables)
        
        viewModel.title
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] title in
                self?.title = title
            })
            .store(in: &cancellables)
        
        viewModel.showError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (title, message) in
                self?.router.showError(title: title, message: message)
            }
            .store(in: &cancellables)
    }
    
    private func setupTableView() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.register(HomeCell.self, forCellReuseIdentifier: HomeCell.description())
    }
    
    @objc private func refresh() {
        viewModel.refresh()
        refreshControl?.endRefreshing()
    }
}

//MARK: - UITableViewDataSource
extension HomeViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.characters.value.count
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

//MARK: - UITableViewDelegate
extension HomeViewController {
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        viewModel.willDisplayItemAt(indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        router.showDetail(id: viewModel.idForRowAt(indexPath.row))
    }
}
