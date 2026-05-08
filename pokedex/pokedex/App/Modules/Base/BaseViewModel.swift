//
//  BaseViewModel.swift
//  pokedex
//
//  Created by Erik Agujari on 30/10/21.
//

struct ErrorAlert: Equatable, Sendable {
    let title: String
    let message: String
}

@MainActor
protocol BaseViewModel: AnyObject {
    var isLoading: Bool { get }
    var errorAlert: ErrorAlert? { get set }
}
