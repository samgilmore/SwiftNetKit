//
//  NetworkService.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

/// A service class to manage network requests.
public class NetworkService {
    
    /// The URLSession used to perform network requests.
    internal let session: URLSession
    
    /// Initializes the NetworkService with a custom configuration and optional timeout interval.
    /// - Parameters:
    ///   - configuration: The session configuration type. Defaults to `.default`.
    ///   - timeoutInterval: An optional timeout interval for requests and resources.
    public init(configuration: SessionConfiguration = .default, timeoutInterval: TimeInterval? = nil) {
        let sessionConfiguration: URLSessionConfiguration
        
        // Determine the session configuration based on the specified type
        switch configuration {
        case .default:
            sessionConfiguration = URLSessionConfiguration.default
        case .ephemeral:
            sessionConfiguration = URLSessionConfiguration.ephemeral
        case .background(let identifier):
            sessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
        }
        
        // Set the timeout interval for the session if specified
        if let timeoutInterval = timeoutInterval {
            sessionConfiguration.timeoutIntervalForRequest = timeoutInterval
            sessionConfiguration.timeoutIntervalForResource = timeoutInterval
        }
        
        // Handle cookie management manually
        sessionConfiguration.httpShouldSetCookies = false
        sessionConfiguration.httpCookieAcceptPolicy = .never
        
        // Create the URLSession with the configured session
        self.session = URLSession(configuration: sessionConfiguration)
    }
    
    /// Configures caching for the URLRequest based on the provided cache configuration.
    /// - Parameters:
    ///   - urlRequest: The URLRequest to be configured.
    ///   - cacheConfiguration: The cache configuration to apply.
    private func configureCache(for urlRequest: inout URLRequest, with cacheConfiguration: CacheConfiguration?) {
        if let cacheConfig = cacheConfiguration {
            // Create a custom URLCache with the specified memory and disk capacity
            let cache = URLCache(
                memoryCapacity: cacheConfig.memoryCapacity,
                diskCapacity: cacheConfig.diskCapacity,
                diskPath: cacheConfig.diskPath
            )
            
            // Set the URLSession's URLCache
            self.session.configuration.urlCache = cache
            
            // Set the cache policy for the URLRequest
            urlRequest.cachePolicy = cacheConfig.cachePolicy
        } else {
            // Use the system-wide default cache if no custom configuration is provided
            self.session.configuration.urlCache = URLCache.shared
        }
    }
    
    /// Asynchronously starts a network request with retries.
    /// - Parameters:
    ///   - request: The request object containing the URL and parameters.
    ///   - retries: The number of retries in case of failure. Defaults to 0.
    ///   - retryInterval: The interval between retries in seconds. Defaults to 1.0.
    /// - Returns: A decoded object of type `T`.
    /// - Throws: An error if the request fails or decoding fails.
    func start<T: Codable>(
        _ request: Request<T>,
        retries: Int = 0,
        retryInterval: TimeInterval = 1.0
    ) async throws -> T {
        var urlRequest = request.buildURLRequest()
        
        // Include cookies in the request if needed
        CookieManager.shared.includeCookiesIfNeeded(for: &urlRequest, includeCookies: request.includeCookies)
        
        // Configure cache for the request
        self.configureCache(for: &urlRequest, with: request.cacheConfiguration)
        
        var currentAttempt = 0
        var lastError: Error?
        
        // Retry loop
        while currentAttempt <= retries {
            do {
                // Perform the network request
                let (data, response) = try await session.data(for: urlRequest)
                
                // Save response cookies if needed
                CookieManager.shared.saveCookiesIfNeeded(from: response, saveResponseCookies: request.saveResponseCookies)
                
                // Validate the HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // Check for successful status code
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                }
                
                // Decode the response data
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
                    // Wait before retrying
                    try await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                }
            }
        }
        
        // Throw the last error if all retries fail
        throw NetworkError.requestFailed(error: lastError ?? NetworkError.unknown)
    }
    
    /// Starts a network request with retries using a completion handler.
    /// - Parameters:
    ///   - request: The request object containing the URL and parameters.
    ///   - retries: The number of retries in case of failure. Defaults to 0.
    ///   - retryInterval: The interval between retries in seconds. Defaults to 1.0.
    ///   - completion: The completion handler to call when the request is complete.
    func start<T: Codable>(
        _ request: Request<T>,
        retries: Int = 0,
        retryInterval: TimeInterval = 1.0,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        var urlRequest = request.buildURLRequest()
        
        // Include cookies in the request if needed
        CookieManager.shared.includeCookiesIfNeeded(for: &urlRequest, includeCookies: request.includeCookies)
        
        // Configure cache for the request
        self.configureCache(for: &urlRequest, with: request.cacheConfiguration)
        
        var currentAttempt = 0
        
        // Define the attempt function for retries
        func attempt() {
            self.session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    if currentAttempt < retries {
                        currentAttempt += 1
                        // Retry after the specified interval
                        DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                            attempt()
                        }
                    } else {
                        completion(.failure(NetworkError.requestFailed(error: error)))
                    }
                    return
                }
                
                // Save response cookies if needed
                CookieManager.shared.saveCookiesIfNeeded(from: response, saveResponseCookies: request.saveResponseCookies)
                
                // Validate the HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(NetworkError.invalidResponse))
                    return
                }
                
                // Check for successful status code
                guard (200..<300).contains(httpResponse.statusCode) else {
                    completion(.failure(NetworkError.serverError(statusCode: httpResponse.statusCode)))
                    return
                }
                
                // Decode the response data
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
        
        // Start the initial attempt
        attempt()
    }
}

extension NetworkService {
    
    /// Starts a batch of network requests asynchronously.
    /// - Parameters:
    ///   - requests: An array of request objects.
    ///   - retries: The number of retries in case of failure. Defaults to 0.
    ///   - retryInterval: The interval between retries in seconds. Defaults to 1.0.
    ///   - exitEarlyOnFailure: A flag indicating whether to exit early on the first failure. Defaults to false.
    /// - Returns: An array of results containing either the decoded response or an error.
    /// - Throws: An error if the request fails and `exitEarlyOnFailure` is set to true.
    func startBatch<T>(
        _ requests: [Request<T>],
        retries: Int = 0,
        retryInterval: TimeInterval = 1.0,
        exitEarlyOnFailure: Bool = false
    ) async throws -> [Result<T, Error>] {
        // Initialize results with failures and prepare for potential errors
        var results = [Result<T, Error>](repeating: .failure(NetworkError.unknown), count: requests.count)
        var encounteredError: Error?
        
        // Use a task group to handle the batch requests concurrently
        try await withThrowingTaskGroup(of: (Int, Result<T, Error>).self) { group in
            for (index, request) in requests.enumerated() {
                group.addTask {
                    do {
                        // Attempt to start the request
                        let response: T = try await self.start(request)
                        return (index, .success(response))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            
            // Process results from the task group
            for try await (index, result) in group {
                if case .failure(let error) = result {
                    if exitEarlyOnFailure {
                        encounteredError = error
                        group.cancelAll()
                        break
                    }
                }
                results[index] = result
            }
        }
        
        // Throw the first encountered error if early exit is enabled
        if exitEarlyOnFailure, let error = encounteredError {
            throw error
        }
        
        return results
    }
    
    /// Starts a batch of network requests with a completion handler.
    /// - Parameters:
    ///   - requests: An array of request objects.
    ///   - retries: The number of retries in case of failure. Defaults to 0.
    ///   - retryInterval: The interval between retries in seconds. Defaults to 1.0.
    ///   - exitEarlyOnFailure: A flag indicating whether to exit early on the first failure. Defaults to false.
    ///   - completion: The completion handler to call when the request is complete.
    func startBatch<T>(
        _ requests: [Request<T>],
        retries: Int = 0,
        retryInterval: TimeInterval = 1.0,
        exitEarlyOnFailure: Bool = false,
        completion: @escaping (Result<[Result<T, Error>], Error>) -> Void
    ) {
        // Initialize results with failures and prepare for potential errors
        var results = [Result<T, Error>](repeating: .failure(NetworkError.unknown), count: requests.count)
        var encounteredError: Error?
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "startBatch.queue", attributes: .concurrent)
        
        // Handle each request in the batch
        for (index, request) in requests.enumerated() {
            dispatchGroup.enter()
            queue.async {
                self.start(request) { result in
                    if exitEarlyOnFailure, case .failure(let error) = result {
                        encounteredError = error
                    }
                    
                    results[index] = result
                    dispatchGroup.leave()
                }
                
                if exitEarlyOnFailure, encounteredError != nil {
                    dispatchGroup.wait()
                    dispatchGroup.leave()
                    return
                }
            }
        }
        
        // Notify when all tasks are complete
        dispatchGroup.notify(queue: .main) {
            if let error = encounteredError {
                completion(.failure(error))
            } else {
                completion(.success(results))
            }
        }
    }
    
    /// Starts a network request with explicit decoding type.
    /// - Parameters:
    ///   - request: The request object containing the URL and parameters.
    ///   - responseType: The type of the response to decode.
    ///   - retries: The number of retries in case of failure. Defaults to 0.
    ///   - retryInterval: The interval between retries in seconds. Defaults to 1.0.
    /// - Returns: A decoded object of the specified type.
    /// - Throws: An error if the request fails or decoding fails.
    private func startWithExplicitType(
        _ request: any RequestProtocol,
        responseType: Decodable.Type,
        retries: Int,
        retryInterval: TimeInterval
    ) async throws -> Any {
        var urlRequest = request.buildURLRequest()
        
        // Include cookies in the request if needed
        CookieManager.shared.includeCookiesIfNeeded(for: &urlRequest, includeCookies: request.includeCookies)
        
        // Configure cache for the request
        self.configureCache(for: &urlRequest, with: request.cacheConfiguration)
        
        var currentAttempt = 0
        var lastError: Error?
        
        // Retry loop
        while currentAttempt <= retries {
            do {
                // Perform the network request
                let (data, response) = try await session.data(for: urlRequest)
                
                // Save response cookies if needed
                CookieManager.shared.saveCookiesIfNeeded(from: response, saveResponseCookies: request.saveResponseCookies)
                
                // Validate the HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // Check for successful status code
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                }
                
                // Decode the response data
                do {
                    let decodedObject = try JSONDecoder().decode(responseType, from: data)
                    return decodedObject
                } catch {
                    throw NetworkError.decodingFailed
                }
            } catch {
                lastError = error
                currentAttempt += 1
                if currentAttempt <= retries {
                    // Wait before retrying
                    try await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
                }
            }
        }
        
        // Throw the last error if all retries fail
        throw NetworkError.requestFailed(error: lastError ?? NetworkError.unknown)
    }
    
    /// Starts a batch of network requests with multiple response types asynchronously.
    /// - Parameters:
    ///   - requests: An array of request objects with different response types.
    ///   - retries: The number of retries in case of failure. Defaults to 0.
    ///   - retryInterval: The interval between retries in seconds. Defaults to 1.0.
    ///   - exitEarlyOnFailure: A flag indicating whether to exit early on the first failure. Defaults to false.
    /// - Returns: An array of results containing either the decoded response or an error.
    /// - Throws: An error if the request fails and `exitEarlyOnFailure` is set to true.
    func startBatchWithMultipleTypes(
        _ requests: [any RequestProtocol],
        retries: Int = 0,
        retryInterval: TimeInterval = 1.0,
        exitEarlyOnFailure: Bool = false
    ) async throws -> [Result<Any, Error>] {
        // Initialize results with failures and prepare for potential errors
        var results = [Result<Any, Error>](repeating: .failure(NetworkError.unknown), count: requests.count)
        var encounteredError: Error?
        
        // Use a task group to handle the batch requests concurrently
        try await withThrowingTaskGroup(of: (Int, Result<Any, Error>).self) { group in
            for (index, request) in requests.enumerated() {
                let responseType = request.responseType
                
                group.addTask {
                    do {
                        // Attempt to start the request with explicit response type
                        let result = try await self.startWithExplicitType(request, responseType: responseType, retries: retries, retryInterval: retryInterval)
                        return (index, .success(result))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            
            // Process results from the task group
            for try await (index, result) in group {
                if case .failure(let error) = result {
                    if exitEarlyOnFailure {
                        encounteredError = error
                        group.cancelAll()
                        break
                    }
                }
                results[index] = result
            }
        }
        
        // Throw the first encountered error if early exit is enabled
        if exitEarlyOnFailure, let error = encounteredError {
            throw error
        }
        
        return results
    }
}
