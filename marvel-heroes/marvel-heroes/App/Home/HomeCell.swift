//
//  HomeCell.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 25/10/21.
//

import UIKit

final class HomeCell: UITableViewCell {
    private lazy var mainImageView: UIImageView = {
        let imageView = UIImageView()
                
        NSLayoutConstraint.activate([imageView.widthAnchor.constraint(equalToConstant: 60),
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
    
    func configure(model: MarvelCharacterModel) {
        titleLabel.text = model.name
        if let modelDescription = model.description, !modelDescription.isEmpty {
            descriptionLabel.text = modelDescription
        } else {
            descriptionLabel.isHidden = true
        }
        pin(view: mainStackView, leading: 10.0, trailing: -10.0, top: 10.0, bottom: -10.0)
    }
    
    func update(image: UIImage) {
        mainImageView.image = image
        mainImageView.layer.cornerRadius = mainImageView.frame.width / 2
        mainImageView.clipsToBounds = true
    }
}
