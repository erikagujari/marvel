//
//  Service.swift
//  marvel-heroes
//
//  Created by Erik Agujari on 23/10/21.
//
import Foundation

enum ServiceMethod: String {
    case get = "GET"
    case post = "POST"
}

protocol Service {
    var baseURL: String { get }
    var path: String { get }
    var parameters: [String: Any]? { get }
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
            let body = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) {
            request.httpBody = body
        }
        printRequest(urlRequest: request)
        return request
    }

    private func printRequest(urlRequest: URLRequest) {
        print("URL: \(String(describing: urlRequest.url?.absoluteString))\nMethod: \(String(describing: urlRequest.httpMethod))\nHeaders: \(String(describing: urlRequest.allHTTPHeaderFields))\nBody: \(String(describing: String(data: urlRequest.httpBody ?? Data(), encoding: .utf8)))\n")
    }

    private var url: URL? {
        var urlComponents = URLComponents(string: baseURL)
        urlComponents?.path = path

        if method == .get {
            guard let parameters = parameters as? [String: String] else { return urlComponents?.url }

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
