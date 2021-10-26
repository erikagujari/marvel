//
//  Spinner.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 26/10/21.
//

import UIKit

final class Spinner: UIView {
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        return activityIndicator
    }()
    
    func show(to view: UIView) {
        view.pin(view: self)
        backgroundColor = .black.withAlphaComponent(0.2)
        pin(view: activityIndicator)
        activityIndicator.startAnimating()
    }
}

extension UIView {
    func showSpinner() {
        let spinner = Spinner()
        spinner.show(to: self)
    }
    
    func dismissSpinner() {
        let spinner = subviews.first(where: { $0 is Spinner })
        spinner?.removeFromSuperview()
    }
}
