//
//  RequestProtocol.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

enum MethodType {
    case get
    case post
    case delete
    case put
    case patch
    
    var stringValue: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        case .delete:
            return "DELETE"
        case .put:
            return "PUT"
        case .patch:
            return "PATCH"
        }
    }
}

protocol RequestProtocol {
    associatedtype ResponseType: Decodable
    
    var url: URL { get }
    var method: MethodType { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}
