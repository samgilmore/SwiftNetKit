//
//  RequestProtocol.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

protocol RequestProtocol {    
    var url: URL { get }
    var method: MethodType { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
    var body: RequestBody? { get }
    var cacheConfiguration: CacheConfiguration? { get }
    var includeCookies: Bool { get }
    var saveResponseCookies: Bool { get }
    
    func buildURLRequest() -> URLRequest
}
