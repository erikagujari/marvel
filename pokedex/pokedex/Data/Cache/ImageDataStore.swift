//
//  ImageDataStore.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 11/11/21.
//

import Foundation

protocol ImageDataStore: Sendable {
    func insert(_ data: Data, for path: String) async throws
    func retrieve(dataForPath path: String) async throws -> Data?
}
