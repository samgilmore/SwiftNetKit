//
//  RequestBody.swift
//
//
//  Created by Sam Gilmore on 7/18/24.
//

import Foundation

/// Types of request bodies that can be sent with a network request.
public enum RequestBody {
    case jsonEncodable(Encodable) // JSON encoded request body
    case data(Data)               // Raw data request body
    case string(String)           // String request body
}
