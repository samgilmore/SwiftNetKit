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
        
        // Default: 60.0s
        if let timeoutInterval = timeoutInterval {
            sessionConfiguration.timeoutIntervalForRequest = timeoutInterval
            sessionConfiguration.timeoutIntervalForResource = timeoutInterval
        }
        
        // Handle cookie management manually
        sessionConfiguration.httpShouldSetCookies = false
        sessionConfiguration.httpCookieAcceptPolicy = .never
        
        self.session = URLSession(configuration: sessionConfiguration)
    }
    
    private func configureCache<T>(for urlRequest: inout URLRequest, with request: Request<T>) {
        if let cacheConfig = request.cacheConfiguration {
            let cache = URLCache(
                memoryCapacity: cacheConfig.memoryCapacity,
                diskCapacity: cacheConfig.diskCapacity,
                diskPath: cacheConfig.diskPath
            )
            
            // Configure the URLSession's URLCache with the specified memory and disk capacity
            self.session.configuration.urlCache = cache
            
            // Set the cache policy for the individual URLRequest, determining how the URLRequest uses the URLCache
            urlRequest.cachePolicy = cacheConfig.cachePolicy
        } else {
            // If no custom cache configuration is provided for this request,
            // then reset the session's URLCache to the system-wide default cache.
            // This ensures that subsequent requests use the default caching behavior
            // provided by URLCache.shared.
            self.session.configuration.urlCache = URLCache.shared
        }
    }
    
    func start<T>(
        _ request: Request<T>,
        retries: Int = 0,
        retryInterval: TimeInterval = 1.0
    ) async throws -> T {
        var urlRequest = request.buildURLRequest()
        
        CookieManager.shared.includeCookiesIfNeeded(for: &urlRequest, includeCookies: request.includeCookies)
        
        self.configureCache(for: &urlRequest, with: request)
        
        var currentAttempt = 0
        var lastError: Error?
        
        while currentAttempt <= retries {
            do {
                let (data, response) = try await session.data(for: urlRequest)
                
                CookieManager.shared.saveCookiesIfNeeded(from: response, saveResponseCookies: request.saveResponseCookies)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                }
                
                do {
                    let decodedObject = try JSONDecoder().decode(T.self, from: data)
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
    
    func start<T>(
        _ request: Request<T>,
        retries: Int = 0,
        retryInterval: TimeInterval = 1.0,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var urlRequest = request.buildURLRequest()
        
        CookieManager.shared.includeCookiesIfNeeded(for: &urlRequest, includeCookies: request.includeCookies)
        
        self.configureCache(for: &urlRequest, with: request)
        
        var currentAttempt = 0
        
        func attempt() {
            self.session.dataTask(with: urlRequest) { data, response, error in
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
                
                CookieManager.shared.saveCookiesIfNeeded(from: response, saveResponseCookies: request.saveResponseCookies)

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
                        let decodedObject = try JSONDecoder().decode(T.self, from: data)
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
