//
//  NetworkError.swift
//
//
//  Created by Sam Gilmore on 7/16/24.
//

/// Errors that can occur during network operations.
public enum NetworkError: Error {
    case invalidResponse                // The response from the server was invalid
    case decodingFailed                 // Failed to decode the response
    case serverError(statusCode: Int)   // Server responded with an error status code
    case requestFailed(error: Error)    // The network request failed
    case unknown                        // An unknown error occurred
}
