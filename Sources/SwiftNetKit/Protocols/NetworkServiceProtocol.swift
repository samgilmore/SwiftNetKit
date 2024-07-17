//
//  NetworkServiceProtocol.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

protocol NetworkServiceProtocol {
    var session: URLSession { get }
    
    // Async/Await
    func start<Request: RequestProtocol>(_ request: Request) async throws -> Request.ResponseType
    
    // Completion Closure
    func start<Request: RequestProtocol>(_ request: Request, completion: @escaping (Result<Request.ResponseType, Error>) -> Void)
}
