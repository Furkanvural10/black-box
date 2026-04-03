//
//  File.swift
//  BlackBox
//
//  Created by furkan vural on 2.04.2026.
//

import Foundation
import UIKit
import SwiftUI

@MainActor
public class NetworkToastManager: @unchecked Sendable {
    
    public static let shared: NetworkToastManager = .init()
    
    private var currentToastWindow: UIWindow?
    private var activeRequests: [UUID: NetworkRequest] = [:]
    private var toastDuration: TimeInterval = 2.0
    private var dismissWorkItem: DispatchWorkItem?
    private var lastToastShowTime: Date?
    private var minimumDisplayTime: TimeInterval = 2
    
    private var isExpanded: Bool = false
    private var pendingRequest: [NetworkRequest] = []
    private var pendingResponse: [NetworkResponse] = []
    
    private init() { }
    
    public func configure(tostDuration: TimeInterval) {
        self.toastDuration = tostDuration
    }
    
    public func showRequest(_ request: NetworkRequest) {
        if currentToastWindow != nil {
            pendingRequest.append(request)
        } else {
            activeRequests[request.id] = request
            presentToast(request: request, response: nil)
        }
    }
    
    public func updateWithResponse(_ response: NetworkResponse) {
        if let index = pendingRequest.firstIndex(where: { $0.id == response.requestID }) {
            pendingResponse.append(response)
            return
        }
        
        guard let request = activeRequests[response.requestID] else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.presentToast(request: request, response: response)
        }
    }
    
    public func setExpanded(_ expanded: Bool) {
        isExpanded = expanded
        if expanded {
            dismissWorkItem?.cancel()
        } else {
            scheduleDismiss()
        }
    }
    
    private func presentToast(request: NetworkRequest, response: NetworkResponse?) {
        lastToastShowTime = Date()
        
        if let window = currentToastWindow, let rootViewController = window.rootViewController {
            
            if #available(iOS 14.0, *) {
                if let hostingController = rootViewController as? UIHostingController<NetworkToastView> {
                    hostingController.rootView = NetworkToastView(
                        request: request,
                        response: response,
                        isExpanded: isExpanded,
                        onDismiss: { [weak self] in
                            self?.forceDismiss()
                        }
                    )
                }
            } else {
                // UIKit
                if let viewController = rootViewController as? NetworkToastViewController {
                    viewController.update(request: request, response: response)
                }
            }
            
            
        } else {
            createWindow(request: request, response: response)
            animateIn()
        }
        
        scheduleDismiss()
    }
    
    private func createWindow(request: NetworkRequest, response: NetworkResponse?) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
            
        
        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = true
        
        if #available(iOS 14.0, *) {
            // SwiftUI
            let hostingController = UIHostingController(
                rootView: NetworkToastView(
                    request: request,
                    response: response,
                    isExpanded: isExpanded, // Pass current state
                    onDismiss: { [weak self] in
                        self?.forceDismiss()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 50)
            )
            hostingController.view.backgroundColor = .clear
            window.rootViewController = hostingController
        } else {
            // UIKit
            let viewController = NetworkToastViewController(
                request: request,
                response: response) { [weak self] in
                    self?.forceDismiss()
                }
            
            window.rootViewController = viewController
            
        }
        
        window.makeKeyAndVisible()
        currentToastWindow = window
        
    }
    
    private func scheduleDismiss() {
        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if !self.isExpanded {
                forceDismiss()
            }
        }
        
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + toastDuration, execute: workItem)
    }
    
    private func forceDismiss() {
        guard let window = currentToastWindow else { return }
        
        UIView.animate(withDuration: 0.4, animations: {
            window.rootViewController?.view.transform = CGAffineTransform(translationX: 0, y: -200)
            window.rootViewController?.view.alpha = 0
            
        }) { _ in
            window.isHidden = true
            self.currentToastWindow = nil
            self.isExpanded = false
            
            self.showNextPendingRequest()
        }
        
    }
    
    private func animateIn() {
        guard let window = currentToastWindow else { return }
        
        window.rootViewController?.view.transform = CGAffineTransform(translationX: 0, y: -200)
        window.rootViewController?.view.alpha = 0
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseOut) {
            window.rootViewController?.view.transform = .identity
            window.rootViewController?.view.alpha = 1
        }

    }
    
    private func showNextPendingRequest() {
        guard !pendingRequest.isEmpty else { return }
        let nextRequest = pendingRequest.removeFirst()
        activeRequests[nextRequest.id] = nextRequest
        
        if let responseIndex = pendingResponse.firstIndex(where: { $0.requestID == nextRequest.id }) {
            let response = pendingResponse.remove(at: responseIndex)
            presentToast(request: nextRequest, response: response)
        } else {
            presentToast(request: nextRequest, response: nil)
        }
    }
    
}
