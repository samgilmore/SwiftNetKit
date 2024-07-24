//
//  NetworkServiceProtocol.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

protocol NetworkServiceProtocol {
    var session: URLSession { get }
    
    // Async / Await
    func start<T>(
        _ request: Request<T>,
        retries: Int,
        retryInterval: TimeInterval
    ) async throws -> T
    
    // Completion Closure
    func start<T>(
        _ request: Request<T>, 
        retries: Int,
        retryInterval: TimeInterval,
        completion: @escaping (Result<T, Error>) -> Void
    )
}
