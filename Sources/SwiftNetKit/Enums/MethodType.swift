//
//  MethodType.swift
//
//
//  Created by Sam Gilmore on 7/17/24.
//

/// HTTP methods used in network requests.
public enum MethodType: String {
    case get    = "GET"     // GET method for retrieving data
    case post   = "POST"    // POST method for sending data
    case delete = "DELETE"  // DELETE method for removing data
    case put    = "PUT"     // PUT method for updating/replacing data
    case patch  = "PATCH"   // PATCH method for partially updating data
}
