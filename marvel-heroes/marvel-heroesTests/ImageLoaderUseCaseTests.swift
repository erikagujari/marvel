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
        let sut = makeSUT(path: path, cachedImageData: cachedImage.pngData())
        let exp = expectation(description: "Waiting to load image")
        var cancellables = Set<AnyCancellable>()
        
        sut.fetch(from: path)
            .sink { result in
                if case .failure = result {
                    XCTFail("It should have succeed with an image")
                }
                exp.fulfill()
            } receiveValue: { image in
                let transformedImage = UIImage(data: cachedImage.pngData()!)!
                XCTAssertEqual(image.pngData(), transformedImage.pngData())
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
    func makeSUT(path: String, httpClientResult: AnyPublisher<Data, MarvelError> = Just(Data()).setFailureType(to: MarvelError.self).eraseToAnyPublisher(), cachedImageData: Data? = nil) -> ImageLoaderUseCase {
        deleteStoreArtifacts()
        let cache = try! CoreDataFeedStore(localURL: testSpecificStoreURL())
        if let cachedImageData = cachedImageData {
            cache.insert(cachedImageData, for: path, completion: { _ in })
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
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func testSpecificStoreURL() -> URL {
        return cachesDirectory().appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
