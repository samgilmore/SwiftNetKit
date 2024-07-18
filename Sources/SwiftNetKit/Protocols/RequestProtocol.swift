//
//  RequestProtocol.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

protocol RequestProtocol {
    associatedtype ResponseType: Decodable
    
    var url: URL { get }
    var method: MethodType { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
    var body: RequestBody? { get }
    
    func buildURLRequest() -> URLRequest
}

extension RequestProtocol {
    func buildURLRequest() -> URLRequest {
        var urlRequest = URLRequest(url: self.url)
        
        if let parameters = self.parameters {
            let queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            var urlComponents = URLComponents(url: self.url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            urlRequest.url = urlComponents?.url
        }
        
        urlRequest.httpMethod = self.method.rawValue
        urlRequest.allHTTPHeaderFields = self.headers
        
        if let body = self.body {
            switch body {
            case .data(let data):
                urlRequest.httpBody = data
            case .string(let string):
                urlRequest.httpBody = string.data(using: .utf8)
            case .jsonEncodable(let encodable):
                let jsonData = try? JSONEncoder().encode(encodable)
                urlRequest.httpBody = jsonData
                
                if headers?["Content-Type"] == nil {
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            }
        }
        
        return urlRequest
    }
}
