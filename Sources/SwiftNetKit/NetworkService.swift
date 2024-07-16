//
//  NetworkService.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

import Foundation

public struct NetworkService {
    
    public init() {}
    
    public func get<T: Decodable>(from url: URL, decodeTo type: T.Type) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            do {
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                return decodedObject
            } catch {
                throw NetworkError.decodingFailed
            }
        } catch {
            throw NetworkError.requestFailed(error: error)
        }
    }
}
