//
//  File.swift
//  BlackBox
//
//  Created by furkan vural on 2.04.2026.
//


import UIKit
import SwiftUI

@MainActor
public class NetworkToastManager: @unchecked Sendable {
    public static let shared = NetworkToastManager()
    
    private var currentToastWindow: UIWindow?
    private var activeRequests: [UUID: NetworkRequest] = [:]
    private var toastDuration: TimeInterval = 2.0
    private var dismissWorkItem: DispatchWorkItem?
    private var lastToastShowTime: Date?
    private let minimumDisplayTime: TimeInterval = 2
    
    private var isExpanded: Bool = false
    private var pendingRequests: [NetworkRequest] = []
    private var pendingResponses: [NetworkResponse] = []
    
    private init() {}
    
    public func configure(toastDuration: TimeInterval) {
        self.toastDuration = toastDuration
    }
    
    public func showRequest(_ request: NetworkRequest) {
        if currentToastWindow != nil {
            pendingRequests.append(request)
        } else {
            activeRequests[request.id] = request
            presentToast(request: request, response: nil)
        }
    }
    
    public func updateWithResponse(_ response: NetworkResponse) {
        if let index = pendingRequests.firstIndex(where: { $0.id == response.requestID }) {
            // Response came for a pending request
             pendingResponses.append(response)
             return
         }

        guard let request = activeRequests[response.requestID] else { return }
        
        // Update immediately to show response info, and reset timer
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
        // Don't dismiss, update if exists
        
        lastToastShowTime = Date()
        
        if let window = currentToastWindow, let rootVC = window.rootViewController {
            // Update existing view
            if #available(iOS 14.0, *) {
                let toastView = NetworkToastView(
                    request: request,
                    response: response,
                    isExpanded: isExpanded,
                    onDismiss: { [weak self] in
                        self?.forceDismiss()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 50)
                
                if let hostingController = rootVC as? UIHostingController<ModifiedContent<ModifiedContent<NetworkToastView, _FrameLayout>, _PaddingLayout>> {
                    hostingController.rootView = toastView as! ModifiedContent<ModifiedContent<NetworkToastView, _FrameLayout>, _PaddingLayout>
                } else if let hostingController = rootVC as? UIHostingController<NetworkToastView> {
                     // Fallback if types don't match exactly due to modifiers
                    hostingController.rootView = toastView as! NetworkToastView
                } else {
                     // Recreate if controller type mismatch (shouldn't happen often)
                     createWindow(request: request, response: response)
                }
            } else {
                // UIKit Fallback update
                if let vc = rootVC as? NetworkToastViewController {
                    vc.update(request: request, response: response)
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
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = true
        
        if #available(iOS 14.0, *) {
            let toastView = NetworkToastView(
                request: request,
                response: response,
                isExpanded: isExpanded,
                onDismiss: { [weak self] in
                    self?.forceDismiss()
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 50)
                let hostingController = UIHostingController(rootView: toastView)
                hostingController.view.backgroundColor = .clear
                window.rootViewController = hostingController
        } else {
            let viewController = NetworkToastViewController(
                request: request,
                response: response,
                onDismiss: { [weak self] in
                    self?.forceDismiss()
                }
            )
            window.rootViewController = viewController
            
        }
        
        window.makeKeyAndVisible()
        currentToastWindow = window
    }
    
    private func animateIn() {
        guard let window = currentToastWindow else { return }
        
        window.rootViewController?.view.transform = CGAffineTransform(translationX: 0, y: -200)
        window.rootViewController?.view.alpha = 0
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
            window.rootViewController?.view.transform = .identity
            window.rootViewController?.view.alpha = 1
        }
    }
    
    private func forceDismiss() {
        guard let window = currentToastWindow else { return }
        
        UIView.animate(withDuration: 0.3, animations: {
            window.rootViewController?.view.transform = CGAffineTransform(translationX: 0, y: -200)
            window.rootViewController?.view.alpha = 0
        }) { _ in
            window.isHidden = true
            self.currentToastWindow = nil
            self.isExpanded = false
            
            self.showNextPendingRequest()
        }
    }
    
    private func scheduleDismiss() {
        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !self.isExpanded {
                self.forceDismiss()
            }
        }
        dismissWorkItem = workItem
        // Use configured duration (e.g. 2.0s) from now
        DispatchQueue.main.asyncAfter(deadline: .now() + toastDuration, execute: workItem)
    }
    
    private func dismissToast() {
        scheduleDismiss()
    }
    
    private func showNextPendingRequest() {
        guard !pendingRequests.isEmpty else { return }
        let nextRequest = pendingRequests.removeFirst()
        activeRequests[nextRequest.id] = nextRequest
        
        // Check if we already have a response for this request
        if let responseIndex = pendingResponses.firstIndex(where: { $0.requestID == nextRequest.id }) {
            let response = pendingResponses.remove(at: responseIndex)
             presentToast(request: nextRequest, response: response)
             scheduleDismiss()
        } else {
            presentToast(request: nextRequest, response: nil)
        }
    }
}
