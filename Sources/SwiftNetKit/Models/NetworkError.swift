//
//  NetworkError.swift
//  
//
//  Created by Sam Gilmore on 7/16/24.
//

public enum NetworkError: Error {
    case invalidResponse
    case decodingFailed
    case serverError(statusCode: Int)
    case requestFailed(error: Error)
}
