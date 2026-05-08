//
//  ImageLoaderUseCaseTests.swift
//  pokedexTests
//
//  Created by Erik Agujari on 27/10/21.
//
@testable import pokedex
import XCTest

final class ImageLoaderUseCaseTests: XCTestCase {
    func test_fetchReturnsCachedImage_onValidCache() async throws {
        let path = "any-path"
        let cachedImage = UIImage(systemName: "star")!
        let sut = try await makeSUT(path: path, cachedImageData: cachedImage.pngData())

        let image = try await sut.fetch(from: path)
        let transformedImage = UIImage(data: cachedImage.pngData()!)!
        XCTAssertEqual(image.pngData(), transformedImage.pngData())
    }

    func test_fetchReturnsError_onClientError() async throws {
        let path = "a path"
        let expected = APIError.mappingError
        let sut = try await makeSUT(path: path, httpClientResult: .failure(expected))

        do {
            _ = try await sut.fetch(from: path)
            XCTFail("Expected failure, got success")
        } catch let error as APIError {
            XCTAssertEqual(error, expected)
        } catch {
            XCTFail("Expected APIError but got \(error)")
        }
    }

    func test_fetchReturnsError_onClientSuccessWithNotValidData() async throws {
        let path = "a path"
        let sut = try await makeSUT(path: path, httpClientResult: .success(Data()))

        do {
            _ = try await sut.fetch(from: path)
            XCTFail("Expected failure, got success")
        } catch let error as APIError {
            XCTAssertEqual(error, .serviceError)
        } catch {
            XCTFail("Expected APIError but got \(error)")
        }
    }

    func test_fetchReturnsSuccessWithImage_onClientSuccessWithValidData() async throws {
        let path = "a path"
        let loadedImage = UIImage(systemName: "star")!
        let sut = try await makeSUT(path: path, httpClientResult: .success(loadedImage.jpegData(compressionQuality: 1.0)!))

        _ = try await sut.fetch(from: path)
    }
}

private extension ImageLoaderUseCaseTests {
    func makeSUT(
        path: String,
        httpClientResult: Result<Data, APIError> = .success(Data()),
        cachedImageData: Data? = nil
    ) async throws -> ImageLoaderUseCase {
        deleteStoreArtifacts()
        let cache = try CoreDataFeedStore(localURL: testSpecificStoreURL())
        if let cachedImageData = cachedImageData {
            try await cache.insert(cachedImageData, for: path)
        }
        let sut = ImageLoaderProvider(client: HTTPClientStub(result: httpClientResult),
                                      cache: cache)
        trackForMemoryLeaks(instance: sut)

        return sut
    }

    struct HTTPClientStub: HTTPClient {
        let result: Result<Data, APIError>

        func fetch(_ request: Service) async throws -> Data {
            try result.get()
        }

        func fetch<T>(_ request: Service, responseType: T.Type) async throws -> T where T: Decodable {
            throw APIError.serviceError
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
