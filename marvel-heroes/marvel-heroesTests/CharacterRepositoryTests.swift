//
//  CharacterRepositoryTests.swift
//  marvel-heroesTests
//
//  Created by Erik Agujari on 23/10/21.
//
import Combine
import XCTest
@testable import marvel_heroes

final class CharacterRepositoryTests: XCTestCase {
    func test_fetchReturnsServiceError_onNilHTTPResponse() {
        let sut = makeSUT(data: nil, urlResponse: nil, error: nil)
        let exp = expectation(description: "Waiting to complete fetch")
        var cancellables = Set<AnyCancellable>()
        
        let _ = sut.fetch(limit: 0, offset: 0)
            .sink { result in
                switch result {
                case let .failure(error):
                    XCTAssertEqual(error as? MarvelError, .serviceError)
                case .finished:
                    XCTFail("It should not succed on nil http response")
                }
                exp.fulfill()
            } receiveValue: { _ in }
            .store(in: &cancellables)
        
        wait(for: [exp], timeout: 0.1)
    }
}

private extension CharacterRepositoryTests {
    func makeSUT(data: Data? = nil, urlResponse: URLResponse? = nil, error: Error? = nil) -> CharacterRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        URLProtocolStub.data = data
        URLProtocolStub.urlResponse = urlResponse
        URLProtocolStub.error = error
        
        return CharacterRepositoryProvider(httpClient: URLSessionHTTPClient(session: URLSession(configuration: configuration)))
    }
    
    class URLProtocolStub: URLProtocol {
        static var urlResponse: URLResponse?
        static var data: Data?
        static var error: Error?
                
        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let error = URLProtocolStub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            if let data = URLProtocolStub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let urlResponse = URLProtocolStub.urlResponse {
                client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
