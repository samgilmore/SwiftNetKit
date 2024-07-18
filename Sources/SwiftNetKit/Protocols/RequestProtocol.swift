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
