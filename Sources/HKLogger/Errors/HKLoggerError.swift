//
//  File.swift
//  
//
//  Created by Bruno Lorenzo on 23/8/22.
//

/// Logger Error Handler
public enum HKLoggerError: Error {
    case couldNotSaveToFile(logMessage: String)
}

public extension HKLoggerError {
    
    /// Friendly message of the erro
    var message: String {
        switch self {
        case .couldNotSaveToFile:
            return "There was an error trying to create the logs directory"
        }
    }
    
    /// Low-level error description
    var debugMessage: String {
        switch self {
        case .couldNotSaveToFile(let logMessage):
            return logMessage
        }
    }
    
}
