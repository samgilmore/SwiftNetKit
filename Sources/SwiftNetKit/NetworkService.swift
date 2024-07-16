//
//  NetworkService.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

public struct NetworkService: NetworkServiceProtocol {
    
    public init() {}
    
    func start<Request: RequestProtocol>(_ request: Request) async throws -> Request.ResponseType {
        do {
            var urlRequest = URLRequest(url: request.url)
            
            if let parameters = request.parameters {
                let queryItems = parameters.map { key, value in
                    URLQueryItem(name: key, value: "\(value)")
                }
                var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
                urlComponents?.queryItems = queryItems
                urlRequest.url = urlComponents?.url
            }
            
            urlRequest.httpMethod = request.method.stringValue
            urlRequest.allHTTPHeaderFields = request.headers
            
            if let body = request.body {
                urlRequest.httpBody = body
            }
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
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
            throw NetworkError.requestFailed(error: error)
        }
    }
    
    func start<Request: RequestProtocol>(_ request: Request, completion: @escaping (Result<Request.ResponseType, Error>) -> Void) {
        var urlRequest = URLRequest(url: request.url)
        
        if let parameters = request.parameters {
            let queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: "\(value)")
            }
            var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = queryItems
            urlRequest.url = urlComponents?.url
        }
        
        urlRequest.httpMethod = request.method.stringValue
        urlRequest.allHTTPHeaderFields = request.headers
        
        if let body = request.body {
            urlRequest.httpBody = body
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(NetworkError.requestFailed(error: error)))
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
}
