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


public class NetworkRequest: @unchecked Sendable { }

public class NetworkResponse: @unchecked Sendable { }
