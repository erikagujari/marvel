//
//  HomeCell.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//

import UIKit

struct HomeCellModel {
    let title: String
    let description: String?
    let cancelAction: (() -> Void)?
    
    var willLoadImage: Bool {
        return cancelAction != nil
    }
}

final class HomeCell: UITableViewCell {
    private lazy var mainImageView: UIImageView = {
        let imageView = UIImageView()
                
        NSLayoutConstraint.activate([imageView.widthAnchor.constraint(equalToConstant: 100),
                                     imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)])
        
        return imageView
    }()
    
    private lazy var imageStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [mainImageView, UIView()])
        stackView.axis = .vertical
        
        return stackView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.numberOfLines = 0
        
        return label
    }()
    
    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        
        return stackView
    }()
    
    private lazy var mainStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageStackView, textStackView])
        stackView.axis = .horizontal
        stackView.spacing = 20.0
        
        return stackView
    }()
    
    var cancelAction: (() -> Void)?
    
    override func prepareForReuse() {
        cancelAction?()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        mainImageView.layer.cornerRadius = mainImageView.frame.width / 2
        mainImageView.layer.borderWidth = 2.0
        mainImageView.layer.borderColor = UIColor.black.cgColor
        mainImageView.clipsToBounds = true
    }
    
    func configure(model: HomeCellModel) {
        titleLabel.text = model.title
        descriptionLabel.text = model.description
        cancelAction = model.cancelAction
        pin(view: mainStackView, leading: 10.0, trailing: -10.0, top: 10.0, bottom: -10.0)
        
        guard model.willLoadImage else { return }
        
        mainImageView.showSpinner()
    }
    
    func update(image: UIImage) {
        mainImageView.dismissSpinner()
        mainImageView.image = image
    }
}
