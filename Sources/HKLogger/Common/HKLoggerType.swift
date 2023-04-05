import Foundation

/// Logs type
public enum HKLoggerType {
    case analytics
    case networking
    case trace
    case health
    case `default`
}

public extension HKLoggerType {
    
    /// Prefix to be used with the log message
    var prefix: String {
        switch self {
        case .analytics:
            return "[ANALYTICS]"
        case .networking:
            return "[NETWORKING]"
        case .trace:
            return "[TRACE]"
        case .health:
            return "[HEALTH]"
        case .default:
            return "[DEFAULT]"
        }
    }
    
}
