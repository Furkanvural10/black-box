//
//  File.swift
//  BlackBox
//
//  Created by furkan vural on 21.02.2026.
//

import Foundation


public class NetworkIntercepter: @unchecked Sendable {
    
    public static let shared: NetworkIntercepter = .init()
    
    private init() { }
    
    private var _isEnabled = false
    private var requestHandlers: [(NetworkRequest) -> Void] = []
    private var responseHandlers: [(NetworkResponse) -> Void] = []
    private let lock = NSLock()
    
    
    public var isEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isEnabled
    }
    
    public func enable() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !_isEnabled else { return }
        
        URLProtocol.registerClass(BlackBoxURLProtocol.self)
        _isEnabled = true
    }
    
    public func disable() {
        lock.lock()
        defer { lock.unlock() }
        
        guard _isEnabled else { return }
        
        URLProtocol.unregisterClass(BlackBoxURLProtocol.self)
        _isEnabled = false
    }
    
    public func onRequestStarted(_ handler: @escaping (NetworkRequest) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        requestHandlers.append(handler)
    }
    
    public func onResponseReceived(_ handler: @escaping (NetworkResponse) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        responseHandlers.append(handler)
    }
    
    func notifyRequestStarted(request: NetworkRequest) {
        lock.lock()
        let handlers = requestHandlers
        
        lock.unlock()
        
        DispatchQueue.main.async {
            handlers.forEach { $0(request) }
        }
    }
    
}


public class NetworkRequest: @unchecked Sendable {
    public let id: UUID
    public let method: String
    public let url: URL
    public let headers: [String: String]
    public let body: Data?
    public let timestamp: Date
    
    init(
        id: UUID = .init(),
        method: String,
        url: URL,
        headers: [String : String] = [:],
        body: Data? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timestamp = timestamp
        
    }
    
    
    public func toCURL() -> String {
        var components = ["curl -X \(method)"]
        components.append("'\(url.absoluteString)'")
        
        for (key, value) in headers {
            components.append("-H '\(key): \(value)'")
        }
        
        if let body, let bodyString = String(data: body, encoding: .utf8) {
            let escapedBody = bodyString.replacingOccurrences(of: "'", with: "'\\''")
            components.append("-d '\(escapedBody)'")
        }
        
        return components.joined(separator: " \\n  ")
    }
}

public class NetworkResponse: @unchecked Sendable {
    
    
    public let requestID: UUID
    public let statusCode: Int
    public let header: [String: String]
    public let data: Data?
    public let duration: TimeInterval
    public let timestamp: Date
    
    init(
        requestID: UUID,
        statusCode: Int,
        header: [String : String] = [:],
        data: Data? = nil,
        duration: TimeInterval,
        timestamp: Date = .init()
    ) {
        self.requestID = requestID
        self.statusCode = statusCode
        self.header = header
        self.data = data
        self.duration = duration
        self.timestamp = timestamp
    }
    
    public var isSuccess: Bool {
        return (200...299).contains(statusCode)
    }
    
    public var formattedDuration: String {
        if duration < 1.0 {
            return String(format: "%.0f ms", duration * 1000)
        } else {
            return String(format: "%.2f s", duration)
        }
    }
    
    public var formattedDataSize: String? {
        guard let data else { return nil }
        
        let bytes = Double(data.count)
        if bytes < 1024 {
            return "\(Int(bytes)) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes * 1024)
        } else {
            return String(format: "%.1f MB", bytes * (1024 * 1024))
        }
    }
    
    public var prettyJSON: String? {
        guard let data else { return nil }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            return String(data: prettyData, encoding: .utf8)
        } catch  {
            return String(data: data, encoding: .utf8)
        }
    }
}
