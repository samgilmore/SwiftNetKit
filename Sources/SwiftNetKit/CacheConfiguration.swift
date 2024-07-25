//
//  CacheConfiguration.swift
//
//
//  Created by Sam Gilmore on 7/19/24.
//

import Foundation

public struct CacheConfiguration {
    var memoryCapacity: Int
    var diskCapacity: Int
    var diskPath: String?
    var cachePolicy: URLRequest.CachePolicy
    
    public init(memoryCapacity: Int = 20 * 1024 * 1024, // 20 MB
                diskCapacity: Int = 100 * 1024 * 1024, // 100 MB
                diskPath: String? = nil,
                cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.memoryCapacity = memoryCapacity
        self.diskCapacity = diskCapacity
        self.diskPath = diskPath
        self.cachePolicy = cachePolicy
    }
}
