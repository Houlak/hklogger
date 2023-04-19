import Foundation

/// Logs type
public enum HKLoggerType {
    case analytics
    case networking(request: URLRequest, response: HTTPURLResponse, body: Data?)
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
    
    /// Message generation to replace log message
    var message: String? {
        switch self {
        case .networking(let request, let response, let body):
            return getMessageFor(request: request, response: response, body: body)
        default:
            return nil
        }
    }
}

private extension HKLoggerType {
    func getMessageFor(request: URLRequest, response: HTTPURLResponse, body: Data?) -> String? {
        let method = request.httpMethod ?? ""
        let path = request.url?.absoluteString ?? ""
        let requestBody = request.httpBody?.toJSONValue
        let requestHeaders = request.allHTTPHeaderFields?.asJSONDictionary
        let responseHeaders = response.allHeaderFields as? [String: String]
        let responseBody = body?.toJSONValue
        
        let logRequest = HKLoggerNetworking.NetworkingRequest(
            headers: requestHeaders,
            body: requestBody
        )
        let logResponse = HKLoggerNetworking.NetworkingResponse(
            statusCode: response.statusCode,
            headers: responseHeaders,
            body: responseBody
        )
        
        let networking = HKLoggerNetworking(
            method: method,
            path: path,
            request: logRequest,
            response: logResponse
        )

        return networking.asJSON
    }
}
