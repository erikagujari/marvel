//
//  Service.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Foundation

enum ServiceMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

protocol Service: Sendable {
    var baseURL: String { get }
    var path: String? { get }
    var parameters: [String: String]? { get }
    var method: ServiceMethod { get }
}

extension Service {
    var urlRequest: URLRequest {
        guard let url = self.url else {
            fatalError("URL could not be built")
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        if method == .post,
            let parameters = parameters,
            let body = try? JSONSerialization.data(withJSONObject: parameters as [String: Any], options: .prettyPrinted) {
            request.httpBody = body
        }
        printRequest(urlRequest: request)
        return request
    }

    private func printRequest(urlRequest: URLRequest) {
        let url = String(describing: urlRequest.url?.absoluteString)
        let method = String(describing: urlRequest.httpMethod)
        let headers = String(describing: urlRequest.allHTTPHeaderFields)
        let body = String(describing: String(data: urlRequest.httpBody ?? Data(), encoding: .utf8))
        print("URL: \(url)\nMethod: \(method)\nHeaders: \(headers)\nBody: \(body)\n")
    }

    private var url: URL? {
        var urlComponents = URLComponents(string: baseURL)
        if let path = path {
            urlComponents?.path = path
        }

        if method == .get {
            guard let parameters = parameters else { return urlComponents?.url }

            urlComponents?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        return urlComponents?.url
    }

    private var headers: [String: String] {
        var dictionary = ["accept": "application/json"]
        if method == .post {
            dictionary.updateValue("application/json", forKey: "Content-Type")
        }
        return dictionary
    }
}
