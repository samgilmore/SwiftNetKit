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
}
