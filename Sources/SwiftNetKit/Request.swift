//
//  Request.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

public class Request<Response: Codable>: RequestProtocol {
    let url: URL
    let method: MethodType
    var parameters: [String : Any]?
    var headers: [String : String]?
    let body: RequestBody?
    let cacheConfiguration: CacheConfiguration?
    let includeCookies: Bool
    let saveResponseCookies: Bool
    
    init(
        url: URL,
        method: MethodType,
        parameters: [String : Any]? = nil,
        headers: [String : String]? = nil,
        body: RequestBody? = nil,
        cacheConfiguration: CacheConfiguration? = nil,
        includeCookies: Bool = true,
        saveResponseCookies: Bool = true
    ) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.body = body
        self.cacheConfiguration = cacheConfiguration
        self.includeCookies = includeCookies
        self.saveResponseCookies = saveResponseCookies
    }
    
    func buildURLRequest() -> URLRequest {
        var urlRequest = URLRequest(url: self.url)
        
        urlRequest.cachePolicy = self.cacheConfiguration?.cachePolicy ?? .useProtocolCachePolicy
        
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
    
    final func addTempCookie(name: String, value: String) {
        let cookie = HTTPCookie(properties: [
            .domain: url.host ?? "",
            .path: "/",
            .name: name,
            .value: value
        ])!
        
        let cookieHeader = HTTPCookie.requestHeaderFields(with: [cookie])
        
        if self.headers == nil {
            self.headers = [:]
        }
        
        for (headerField, headerValue) in cookieHeader {
            if let existingValue = self.headers?[headerField] {
                self.headers?[headerField] = existingValue + "; " + headerValue
            } else {
                self.headers?[headerField] = headerValue
            }
        }
    }
}
