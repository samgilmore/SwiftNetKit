//
//  Request.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

/// Represents a network request with a generic response type.
/// - Parameter Response: The type of the response expected from the request, which conforms to `Codable`.
public class Request<Response: Codable>: RequestProtocol {
    let url: URL
    let method: MethodType
    var parameters: [String: Any]?
    var headers: [String: String]?
    let body: RequestBody?
    let cacheConfiguration: CacheConfiguration?
    let includeCookies: Bool
    let saveResponseCookies: Bool
    var responseType: Response.Type { return Response.self }
    
    /// Initializes a new request.
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - method: The HTTP method (e.g., GET, POST).
    ///   - parameters: Optional query parameters to be included in the request.
    ///   - headers: Optional headers to be included in the request.
    ///   - body: Optional body content for the request.
    ///   - cacheConfiguration: Optional cache configuration for the request.
    ///   - includeCookies: Flag indicating whether to include cookies in the request. Defaults to true.
    ///   - saveResponseCookies: Flag indicating whether to save cookies from the response. Defaults to true.
    init(
        url: URL,
        method: MethodType,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil,
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
    
    /// Builds and returns a `URLRequest` from the request configuration.
    /// - Returns: A `URLRequest` configured with the URL, method, parameters, headers, and body.
    func buildURLRequest() -> URLRequest {
        var urlRequest = URLRequest(url: self.url)
        
        // Set the cache policy
        urlRequest.cachePolicy = self.cacheConfiguration?.cachePolicy ?? .useProtocolCachePolicy
        
        // Add query parameters to the URL if present
        if let parameters = self.parameters {
            let queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            var urlComponents = URLComponents(url: self.url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            urlRequest.url = urlComponents?.url
        }
        
        // Set the HTTP method
        urlRequest.httpMethod = self.method.rawValue
        // Set the HTTP headers
        urlRequest.allHTTPHeaderFields = self.headers
        
        // Set the HTTP body based on the request body type
        if let body = self.body {
            switch body {
            case .data(let data):
                urlRequest.httpBody = data
            case .string(let string):
                urlRequest.httpBody = string.data(using: .utf8)
            case .jsonEncodable(let encodable):
                let jsonData = try? JSONEncoder().encode(encodable)
                urlRequest.httpBody = jsonData
                
                // Set content type header if not already set
                if headers?["Content-Type"] == nil {
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            }
        }
        
        return urlRequest
    }
    
    /// Adds a temporary cookie to the request headers.
    /// - Parameters:
    ///   - name: The name of the cookie.
    ///   - value: The value of the cookie.
    final func addTempCookie(name: String, value: String) {
        // Create an HTTPCookie with the specified name and value
        let cookie = HTTPCookie(properties: [
            .domain: url.host ?? "",
            .path: "/",
            .name: name,
            .value: value
        ])!
        
        // Generate cookie headers
        let cookieHeader = HTTPCookie.requestHeaderFields(with: [cookie])
        
        // Initialize headers if they are nil
        if self.headers == nil {
            self.headers = [:]
        }
        
        // Add or update the cookie header in the request headers
        for (headerField, headerValue) in cookieHeader {
            if let existingValue = self.headers?[headerField] {
                self.headers?[headerField] = existingValue + "; " + headerValue
            } else {
                self.headers?[headerField] = headerValue
            }
        }
    }
}
