//
//  BaseViewModel.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 30/10/21.
//
import Combine

protocol BaseViewModel {
    var showSpinner: PassthroughSubject<Bool, Never> { get }
    var showError: PassthroughSubject<(String, String), Never> { get }
}
