//
//  ImageLoaderUseCase.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 26/10/21.
//

import Combine
import UIKit

protocol ImageLoaderUseCase {
    func fetch(from path: String, completion: @escaping (Result<UIImage, Error>) -> Void)
    func cancel()
}

final class ImageLoaderProvider: ImageLoaderUseCase {
    private let session: URLSession
    private let cache: NSCache<NSString, UIImage>
    private var task: URLSessionDataTask?
    
    init(session: URLSession) {
        self.session = session
        self.cache = NSCache()
    }
    
    func fetch(from path: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let cachedImage = cache.object(forKey: path as NSString) else {
            guard let url = URL(string: path) else {
                completion(.failure(MarvelError.serviceError))
                return
            }
            
            task = session.dataTask(with: url) { [weak self] data, urlResponse, error in
                if let error = error {
                    completion(.failure(error))
                }
                if let data = data,
                   let image = UIImage(data: data) {
                    self?.cache.setObject(image, forKey: path as NSString)
                    completion(.success(image))
                }
            }
            task?.resume()
            return
        }
        
        completion(.success(cachedImage))
    }
    
    func cancel() {
        task?.cancel()
    }
}
