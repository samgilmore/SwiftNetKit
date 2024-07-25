//
//  SessionConfiguration.swift
//
//
//  Created by Sam Gilmore on 7/17/24.
//

/// Configurations for URL sessions.
public enum SessionConfiguration {
    case `default`                // Default session configuration
    case ephemeral                // Ephemeral session configuration (no persistent storage)
    case background(String)       // Background session configuration with a specified identifier
}
