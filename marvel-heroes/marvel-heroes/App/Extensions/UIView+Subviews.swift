//
//  UIView+Subviews.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//
import UIKit

extension UIView {
    func pin(view: UIView, leading: CGFloat = 0.0, trailing: CGFloat = 0.0, top: CGFloat = 0.0, bottom: CGFloat = 0.0) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: leading),
            view.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: trailing),
            view.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: top),
            view.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: bottom)
        ])
    }
}
