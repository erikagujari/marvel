//
//  DetailRouter.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//

import UIKit

protocol DetailRouterProtocol {
    var viewController: UIViewController? { get }
}

final class DetailRouter: DetailRouterProtocol {
    var viewController: UIViewController?
}
