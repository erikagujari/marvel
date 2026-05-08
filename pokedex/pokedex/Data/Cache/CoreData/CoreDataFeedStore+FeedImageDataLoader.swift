//
//  CoreDataFeedStore+FeedImageDataLoader.swift
//  pokedex
//
//  Created by Erik Agujari on 11/11/21.
//
import CoreData

extension CoreDataFeedStore: ImageDataStore {
    func insert(_ data: Data, for path: String) async throws {
        try await perform { context in
            let image = CoreDataFeedImage(context: context)
            image.id = UUID()
            image.data = data
            image.path = path
            try context.save()
        }
    }

    func retrieve(dataForPath path: String) async throws -> Data? {
        try await perform { context in
            let dataArray: [CoreDataFeedImage] = try context.fetch(CoreDataFeedImage.fetchRequest())
            guard let first = dataArray.first(where: { $0.path == path }) else {
                throw APIError.cacheError
            }
            return first.data
        }
    }
}
