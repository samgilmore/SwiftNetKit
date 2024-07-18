//
//  BaseRequest.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

public struct BaseRequest<Response: Decodable>: RequestProtocol {
    typealias ResponseType = Response
    
    let url: URL
    let method: MethodType
    let parameters: [String : Any]?
    let headers: [String : String]?
    let body: RequestBody?
    
    init(
        url: URL,
        method: MethodType,
        parameters: [String : Any]? = nil,
        headers: [String : String]? = nil,
        body: RequestBody? = nil
    ) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.body = body
    }
    
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
            }
        }
        
        return urlRequest
    }
}
