//
//  DetailRouter.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//

import UIKit

protocol DetailRouterProtocol {
    var viewController: UIViewController? { get }
    func showError(title: String, message: String)
}

final class DetailRouter: DetailRouterProtocol {
    weak var viewController: UIViewController?
    
    func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Ok",
                                                style: .default,
                                                handler: { _ in
            alertController.dismiss(animated: true) { [weak self] in
                self?.viewController?.navigationController?.popViewController(animated: true)
            }
        }))
        
        viewController?.present(alertController, animated: true)
    }
}
