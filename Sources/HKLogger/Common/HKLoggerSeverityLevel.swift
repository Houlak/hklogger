import Foundation

/// Logs severity
public enum HKLoggerSeverityLevel {
    case debug
    case info
    case warning
    case error
}

public extension HKLoggerSeverityLevel {
    
    /// Icon to be used in the console with the log message
    var icon: String {
        switch self {
        case .debug:
            return ""
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        }
    }
    
    /// Prefix to be used with the log message
    var prefix: String {
        switch self {
        case .debug:
            return "[DEBUG]"
        case .info:
            return "[INFO]"
        case .warning:
            return "[WARNING]"
        case .error:
            return "[ERROR]"
        }
    }
    
}
