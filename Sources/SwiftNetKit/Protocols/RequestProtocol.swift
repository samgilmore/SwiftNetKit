//
//  RequestProtocol.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

protocol RequestProtocol {
    associatedtype Response: Codable
    
    var url: URL { get }
    var method: MethodType { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
    var body: RequestBody? { get }
    var cacheConfiguration: CacheConfiguration? { get }
    var includeCookies: Bool { get }
    var saveResponseCookies: Bool { get }
    var responseType: Response.Type { get }
    
    func buildURLRequest() -> URLRequest
}
