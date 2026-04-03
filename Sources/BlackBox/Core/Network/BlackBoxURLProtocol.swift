//
//  BlackBoxURLProtocol.swift
//  ShakeLog
//
//  Created by furkan vural on 12.02.2026.
//

import Foundation

class BlackBoxURLProtocol: URLProtocol, @unchecked Sendable {
    
    
    
    private var dataTask: URLSessionDataTask?
    private var receivedData: NSMutableData?
    private var requestTime: Date?
    private var requestId: UUID? // Request - Response -> Match
    
    private static let requestIdKey = "BlackBoxRequestIDKey"
    
    override class func canInit(with request: URLRequest) -> Bool {
        
        guard NetworkIntercepter.shared.isEnabled else { return false }
        if URLProtocol.property(forKey: requestIdKey, in: request) != nil {
            return false
        }
        
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url else {
            return
        }
        
        let id = UUID()
        requestId = id
        requestTime = Date()
        
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(id.uuidString, forKey: BlackBoxURLProtocol.requestIdKey, in: mutableRequest)
        
        let networkRequest = NetworkRequest(id: id, method: request.httpMethod ?? "GET", url: url, headers: request.allHTTPHeaderFields ?? [:], body: request.httpBody)
        
        #warning("Fix this dependency")
        NetworkIntercepter.shared.notifyRequestStarted(request: networkRequest)
                
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        dataTask = session.dataTask(with: mutableRequest as URLRequest)
        dataTask?.resume()
    }
    
    override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }
}

extension BlackBoxURLProtocol: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
        receivedData = NSMutableData()
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        receivedData?.append(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
        
        guard let requestId = requestId,
              let startTime = requestTime,
              let httpResponse = task.response as? HTTPURLResponse else {
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        let networkResponse = NetworkResponse(
            requestID: requestId,
            statusCode: httpResponse.statusCode,
            headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
            data: receivedData as Data?,
            duration: duration,
        )
        
        #warning("Fix dependency")
        NetworkIntercepter.shared.notifyResponseReceived(networkResponse)
        
        
    }
}
