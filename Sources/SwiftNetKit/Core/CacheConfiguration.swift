//
//  CacheConfiguration.swift
//
//
//  Created by Sam Gilmore on 7/19/24.
//

import Foundation

/// Configuration options for caching network responses.
public struct CacheConfiguration {
    /// The memory capacity of the cache, in bytes.
    public var memoryCapacity: Int
    
    /// The disk capacity of the cache, in bytes.
    public var diskCapacity: Int
    
    /// The path for the disk cache storage.
    public var diskPath: String?
    
    /// The cache policy for the request.
    public var cachePolicy: URLRequest.CachePolicy
    
    /// Initializes a new cache configuration with the provided parameters.
    ///
    /// - Parameters:
    ///   - memoryCapacity: The memory capacity of the cache, in bytes. Default is 20 MB.
    ///   - diskCapacity: The disk capacity of the cache, in bytes. Default is 100 MB.
    ///   - diskPath: The path for the disk cache storage. Default is `nil`.
    ///   - cachePolicy: The cache policy for the request. Default is `.useProtocolCachePolicy`.
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
