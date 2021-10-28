//
//  HomeCellModel.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 28/10/21.
//

struct HomeCellModel {
    let title: String
    let description: String?
    let cancelAction: (() -> Void)?
    
    var willLoadImage: Bool {
        return cancelAction != nil
    }
}
