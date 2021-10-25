//
//  HomeViewController.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine
import UIKit

final class HomeViewController: UITableViewController {
    private let viewModel: HomeViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
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
    }
    
    private func setupTableView() {
        tableView.register(HomeCell.self, forCellReuseIdentifier: HomeCell.description())
    }
    
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
        
        cell.configure(model: viewModel.characters.value[indexPath.row])
        
        return cell
    }
}
