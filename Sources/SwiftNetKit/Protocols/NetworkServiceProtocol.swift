//
//  NetworkServiceProtocol.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

protocol NetworkServiceProtocol {
    // Async/Await
    func start<Request: RequestProtocol>(_ request: Request) async throws -> Request.ResponseType
    
    // Completion Closure
    func start<Request: RequestProtocol>(_ request: Request, completion: @escaping (Result<Request.ResponseType, Error>) -> Void)
}
