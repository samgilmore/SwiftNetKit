//
//  NetworkService.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

public struct NetworkService: NetworkServiceProtocol {
    
    internal let session: URLSession
    
    public init(configuration: SessionConfiguration = .default, timeoutInterval: TimeInterval? = nil) {
        let sessionConfiguration: URLSessionConfiguration
        switch configuration {
        case .default:
            sessionConfiguration = URLSessionConfiguration.default
        case .ephemeral:
            sessionConfiguration = URLSessionConfiguration.ephemeral
        case .background(let identifier):
            sessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
        }
        
        if let timeoutInterval = timeoutInterval {
            sessionConfiguration.timeoutIntervalForRequest = timeoutInterval
            sessionConfiguration.timeoutIntervalForResource = timeoutInterval
        }
        
        self.session = URLSession(configuration: sessionConfiguration)
    }
    
    func start<Request: RequestProtocol>(
        _ request: Request,
        retries: Int = 0,
        retryInterval: TimeInterval = 1.0
    ) async throws -> Request.ResponseType {
        var currentAttempt = 0
        var lastError: Error?
        
        while currentAttempt <= retries {
            do {
                let urlRequest = request.buildURLRequest()
                
                let (data, response) = try await session.data(for: urlRequest)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                }
                
                do {
                    let decodedObject = try JSONDecoder().decode(Request.ResponseType.self, from: data)
                    return decodedObject
                } catch {
                    throw NetworkError.decodingFailed
                }
            } catch {
                lastError = error
                currentAttempt += 1
                if currentAttempt <= retries {
                    try await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                }
            }
        }
        
        throw NetworkError.requestFailed(error: lastError ?? NetworkError.unknown)
    }
    
    func start<Request: RequestProtocol>(
        _ request: Request,
        retries: Int = 0,
        retryInterval: TimeInterval = 1.0,
        completion: @escaping (Result<Request.ResponseType, Error>) -> Void
    ) {
        var currentAttempt = 0
        
        func attempt() {
            let urlRequest = request.buildURLRequest()
            
            session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    if currentAttempt < retries {
                        currentAttempt += 1
                        DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                            attempt()
                        }
                    } else {
                        completion(.failure(NetworkError.requestFailed(error: error)))
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                guard (200..<300).contains(httpResponse.statusCode) else {
                    completion(.failure(NetworkError.serverError(statusCode: httpResponse.statusCode)))
                    return
                }
                
                if let data = data {
                    do {
                        let decodedObject = try JSONDecoder().decode(Request.ResponseType.self, from: data)
                        completion(.success(decodedObject))
                    } catch {
                        completion(.failure(NetworkError.decodingFailed))
                    }
                } else {
                    completion(.failure(NetworkError.invalidResponse))
                }
            }.resume()
        }
        
        attempt()
    }
}
