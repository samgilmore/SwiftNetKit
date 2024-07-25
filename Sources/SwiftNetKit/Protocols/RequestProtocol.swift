//
//  RequestProtocol.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

/// A protocol that defines the requirements for making a network request.
protocol RequestProtocol {
    /// The type of the response expected from the request.
    associatedtype Response: Codable
    
    /// The URL of the request.
    var url: URL { get }
    
    /// The HTTP method of the request.
    var method: MethodType { get }
    
    /// The parameters to be sent with the request.
    var parameters: [String: Any]? { get }
    
    /// The headers to be included in the request.
    var headers: [String: String]? { get }
    
    /// The body of the request.
    var body: RequestBody? { get }
    
    /// The cache configuration for the request.
    var cacheConfiguration: CacheConfiguration? { get }
    
    /// Indicates whether cookies should be included in the request.
    var includeCookies: Bool { get }
    
    /// Indicates whether response cookies should be saved.
    var saveResponseCookies: Bool { get }
    
    /// The type of the response expected from the request.
    var responseType: Response.Type { get }
    
    /// Builds and returns a URLRequest object based on the protocol properties.
    ///
    /// - Returns: A URLRequest object configured with the protocol properties.
    func buildURLRequest() -> URLRequest
}
