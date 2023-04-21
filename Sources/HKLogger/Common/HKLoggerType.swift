import Foundation

/// Logs type
public enum HKLoggerType {
    case analytics
    case networking(request: URLRequest, response: HTTPURLResponse, responseBody: Data?)
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
        case .networking(let request, let response, let responseBody):
            return getMessageFor(request: request, response: response, responseBody: responseBody)
        default:
            return nil
        }
    }
}

private extension HKLoggerType {
    func getMessageFor(request: URLRequest, response: HTTPURLResponse, responseBody: Data?) -> String? {
        let method = request.httpMethod ?? ""
        let path = request.url?.absoluteString ?? ""
        
        let networking = HKLoggerNetworking(
            method: method,
            path: path,
            request: getNetworkingRequest(for: request),
            response: getNetworkingResponse(for: response, with: responseBody)
        )
        
        return networking.asJSON
    }
    
    func getNetworkingRequest(for request: URLRequest) -> HKLoggerNetworking.NetworkingRequest? {
        let body = request.httpBody?.toJSONValue
        let headers = request.allHTTPHeaderFields?.asJSONDictionary
        
        if headers == nil && body == nil {
            return nil
        } else {
            return HKLoggerNetworking.NetworkingRequest(
                headers: headers,
                body: body
            )
        }
    }
    
    func getNetworkingResponse(for response: HTTPURLResponse, with body: Data?) -> HKLoggerNetworking.NetworkingResponse? {
        let headers = response.allHeaderFields as? [String: String]
        let responseBody = body?.toJSONValue
        let statusCode = response.statusCode
        
        return HKLoggerNetworking.NetworkingResponse(
            statusCode: statusCode,
            headers: headers?.isEmpty == true ? nil : headers,
            body: responseBody
        )
    }
}
