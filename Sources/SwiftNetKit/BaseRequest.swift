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
    let body: Data?
    
    init(
        url: URL,
        method: MethodType,
        parameters: [String : Any]? = nil,
        headers: [String : String]? = nil,
        body: Data? = nil
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
            urlRequest.httpBody = body
        }
        
        return urlRequest
    }
}
