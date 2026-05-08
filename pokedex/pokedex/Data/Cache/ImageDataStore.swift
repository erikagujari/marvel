//
//  ImageDataStore.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 11/11/21.
//

import Foundation

protocol ImageDataStore {
    typealias RetrievalResult = Result<Data?, Error>
    typealias InsertionResult = Result<Void, Error>

    func insert(_ data: Data, for path: String, completion: @escaping (InsertionResult) -> Void)
    func retrieve(dataForPath path: String, completion: @escaping (RetrievalResult) -> Void)
}
