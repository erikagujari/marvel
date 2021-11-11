//
//  CoreDataFeedStore+FeedImageDataLoader.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 11/11/21.
//
import CoreData

extension CoreDataFeedStore: ImageDataStore {
    func insert(_ data: Data, for path: String, completion: @escaping (InsertionResult) -> Void) {
        perform { context in
            let image = CoreDataFeedImage(context: context)
            image.id = UUID()
            image.data = data
            image.path = path
                        
            do {
                try context.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func retrieve(dataForPath path: String, completion: @escaping (RetrievalResult) -> Void) {
        perform { context in
            do {
                let dataArray: [CoreDataFeedImage] = try context.fetch(CoreDataFeedImage.fetchRequest())
                guard let first = dataArray.first(where: { $0.path == path }) else {
                    completion(.failure(MarvelError.cacheError))
                    return
                }
                
                completion(.success(first.data))
            } catch let error {
                completion(.failure(error))
            }
        }
    }
}
