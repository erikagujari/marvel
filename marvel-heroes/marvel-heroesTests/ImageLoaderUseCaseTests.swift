//
//  ImageLoaderUseCaseTests.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 27/10/21.
//

import XCTest
import Combine
@testable import marvel_heroes

final class ImageLoaderUseCaseTests: XCTestCase {
    func test_fetchReturnsCachedImage_onValidCache() {
        let path = "any-path"
        let cachedImage = UIImage(systemName: "star")!
        let sut = makeSUT(path: path, cachedImage: cachedImage)
        let exp = expectation(description: "Waiting to load image")
        var cancellables = Set<AnyCancellable>()
        
        sut.fetch(from: path)
            .sink { result in
                exp.fulfill()
            } receiveValue: { image in
                XCTAssertEqual(image, cachedImage)
            }
            .store(in: &cancellables)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_fetchReturnsError_onClientError() {
        let path = "a path"
        let error = MarvelError.mappingError
        let sut = makeSUT(path: path, httpClientResult: Fail(error: error).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to load image")
        var cancellables = Set<AnyCancellable>()
        
        sut.fetch(from: path)
            .sink { result in
                switch result {
                case let .failure(receivedError):
                    XCTAssertEqual(error, receivedError)
                case .finished:
                    XCTFail("The result should be a failure")
                }
                exp.fulfill()
            } receiveValue: { _ in
                
            }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }
    
    func test_fetchReturnsError_onClientSuccessWithNotValidData() {
        let path = "a path"
        let sut = makeSUT(path: path, httpClientResult: Just(Data()).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to load image")
        var cancellables = Set<AnyCancellable>()
        
        sut.fetch(from: path)
            .sink { result in
                switch result {
                case let .failure(receivedError):
                    XCTAssertEqual(.serviceError, receivedError)
                case .finished:
                    XCTFail("The result should be a failure")
                }
                exp.fulfill()
            } receiveValue: { _ in
                
            }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }
    
    func test_fetchReturnsSuccessWithImage_onClientSuccessWithValidData() {
        let path = "a path"
        let loadedImage = UIImage(systemName: "star")!
        let sut = makeSUT(path: path, httpClientResult: Just(loadedImage.jpegData(compressionQuality: 1.0)!).setFailureType(to: MarvelError.self).eraseToAnyPublisher())
        let exp = expectation(description: "Waiting to load image")
        var cancellables = Set<AnyCancellable>()
        
        sut.fetch(from: path)
            .sink { result in
                switch result {
                case .finished: break
                case let .failure(error):
                    XCTFail(error.localizedDescription)
                }
                exp.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)

        wait(for: [exp], timeout: 1.0)
    }
}

private extension ImageLoaderUseCaseTests {
    func makeSUT(path: String, httpClientResult: AnyPublisher<Data, MarvelError> = Just(Data()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(), cachedImage: UIImage? = nil) -> ImageLoaderUseCase {
        let cache = CacheSpy()
        cache.removeAllObjects()
        if let cachedImage = cachedImage {
            cache.setObject(cachedImage, forKey: path as NSString)
        }
        let sut = ImageLoaderProvider(client: HTTPClientStub(result: httpClientResult),
                                      cache: cache)
        trackForMemoryLeaks(instance: sut)
        
        return sut
    }
                                      
    struct HTTPClientStub: HTTPClient {
        let result: AnyPublisher<Data, MarvelError>
        
        func fetch(request: Service) -> AnyPublisher<Data, MarvelError> {
            return result
        }
        
        func fetch<T>(_ request: Service, responseType: T.Type) -> AnyPublisher<T, MarvelError> where T : Decodable {
            return Just("" as! T).setFailureType(to: MarvelError.self).eraseToAnyPublisher()
        }
    }
    
    class CacheSpy: NSCache<NSString, UIImage> {
        
    }
}

