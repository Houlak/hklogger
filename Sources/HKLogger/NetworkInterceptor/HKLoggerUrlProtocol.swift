//
//  File.swift
//  
//
//  Created by Juan Rodríguez HK on 18/5/23.
//

import Foundation

class HKLoggerUrlProtocol: URLProtocol {
    var session: URLSession?
    var sessionTask: URLSessionDataTask?
    
    var response: HTTPURLResponse?
    
//    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
//        super.init(request: request, cachedResponse: cachedResponse, client: client)
//
//        if session == nil {
//            session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
//        }
//    }
//
//
//    override class func canInit(with request: URLRequest) -> Bool {
//        return true
//    }
//
//    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
//        return request
//    }
//
//    override func startLoading() {
//        sessionTask = session?.dataTask(with: request as URLRequest)
//        sessionTask?.resume()
//    }
//
//    override func stopLoading() {
//        sessionTask?.cancel()
//        session?.invalidateAndCancel()
//    }
}

extension HKLoggerUrlProtocol: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
     
        if let response = dataTask.response as? HTTPURLResponse {
            HKLogger.shared.log(
                message: "HKLogger - Network",
                severity: .debug,
                type: .networking(
                    request: self.request,
                    response: response,
                    responseBody: data
                )
            )
        }
        
        
        client?.urlProtocol(self, didLoad: data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let policy = URLCache.StoragePolicy(rawValue: request.cachePolicy.rawValue) ?? .notAllowed
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: policy)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error = error else { return }
        client?.urlProtocol(self, didFailWithError: error)
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let protectionSpace = challenge.protectionSpace
        let sender = challenge.sender
        
        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                sender?.use(credential, for: challenge)
                completionHandler(.useCredential, credential)
                return
            }
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        client?.urlProtocolDidFinishLoading(self)
    }
    
}
