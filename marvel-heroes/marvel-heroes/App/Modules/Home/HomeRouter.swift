//
//  HomeRouter.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//
import UIKit

protocol HomeRouterProtocol {
    var viewController: UIViewController? { get set }
    func showError(title: String, message: String)
    func showDetail(id: Int)
}

final class HomeRouter: HomeRouterProtocol {
    weak var viewController: UIViewController?
            
    func showError(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Ok",
                                                style: .default,
                                                handler: { _ in
            alertController.dismiss(animated: true)
        }))
        
        viewController?.present(alertController, animated: true)
    }
    
    func showDetail(id: Int) {
        
    }
}
