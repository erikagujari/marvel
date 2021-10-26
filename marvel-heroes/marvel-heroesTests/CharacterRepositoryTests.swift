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
        
        expect(sut: sut, endsWithResult: .failure(.serviceError))
    }
    
    func test_fetchReturnsServiceError_onNotHTTPURLResponse() {
        let sut = makeSUT(data: nil, urlResponse: URLResponse(), error: nil)
        
        expect(sut: sut, endsWithResult: .failure(.serviceError))
    }
    
    func test_fetchReturnsServiceError_on199StatusCode() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 199,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: nil, urlResponse: urlResponse, error: nil)
        
        expect(sut: sut, endsWithResult: .failure(.serviceError))
    }
    
    func test_fetchReturnsServiceError_on300StatusCode() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 300,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: nil, urlResponse: urlResponse, error: nil)
        
        expect(sut: sut, endsWithResult: .failure(.serviceError))
    }
    
    func test_fetchReturnsMappingError_onNilData() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: nil, urlResponse: urlResponse, error: nil)
        
        expect(sut: sut, endsWithResult: .failure(.mappingError))
    }
    
    func test_fetchReturnsMappingError_onEmptyData() {
        let data = "".data(using: .utf8)
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: data, urlResponse: urlResponse, error: nil)
        
        expect(sut: sut, endsWithResult: .failure(.mappingError))
    }
    
    func test_fetchReturnsMappingError_onInvalidData() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: anyInvalidJSON(), urlResponse: urlResponse, error: nil)
        
        expect(sut: sut, endsWithResult: .failure(.mappingError))
    }
    
    func test_fetchReturnsCharacters_onValidData() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: anyValidJSON(), urlResponse: urlResponse, error: nil)
        
        expect(sut: sut, endsWithResult: .finished)
    }
    
    func test_fetchReturnsServiceError_onAnyError() {
        let urlResponse = HTTPURLResponse(url: URL(string: "https://any-url.com")!,
                                          statusCode: 200,
                                          httpVersion: nil,
                                          headerFields: nil)
        let sut = makeSUT(data: anyValidJSON(), urlResponse: urlResponse, error: MarvelError.mappingError)
        
        expect(sut: sut, endsWithResult: .failure(.serviceError))
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
    
    func expect(sut: CharacterRepository, endsWithResult expectedResult: Subscribers.Completion<MarvelError>, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Waiting to complete fetch")
        var cancellables = Set<AnyCancellable>()
        
        sut.fetch(parameters: CharacterService.ListParameters(limit: 0, offset: 0, apiKey: "", timestamp: "", hash: ""))
            .sink { receivedResult in
                XCTAssertEqual(expectedResult, receivedResult, file: file, line: line)
                exp.fulfill()
            } receiveValue: { characters in
                XCTAssertFalse(characters.isEmpty)
            }
            .store(in: &cancellables)
        
        wait(for: [exp], timeout: 2)
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
