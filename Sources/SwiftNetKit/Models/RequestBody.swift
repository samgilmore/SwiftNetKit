//
//  RequestBody.swift
//
//
//  Created by Sam Gilmore on 7/18/24.
//

import Foundation

public enum RequestBody {
    case jsonEncodable(Encodable)
    case data(Data)
    case string(String)
}
