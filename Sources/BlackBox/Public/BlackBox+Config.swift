//
//  File.swift
//  BlackBox
//
//  Created by furkan vural on 3.04.2026.
//

import Foundation


public extension BlackBox {
    
    struct Config {
        public enum PresentationMode {
            case uiKit
            case swiftUI
        }
        
        public var presentationMode: PresentationMode = .uiKit
        public var enableNetworkInterception: Bool = false
        public var showNetworkToast: Bool = true
        public var toastDuration: TimeInterval = 6.0
        
        public init() { }
    }
    
    @MainActor static var config = Config()
    
    @MainActor static func configure(_ config: Config) {
        #if DEBUG
        self.config = config
        
        if config.enableNetworkInterception {
            NetworkIntercepter.shared.enable()
            
            if config.showNetworkToast {
                NetworkToastManager.shared.configure(toastDuration: config.toastDuration)
                
                NetworkIntercepter.shared.onRequestStarted { request in
                    NetworkToastManager.shared.showRequest(request)
                }
                
                NetworkIntercepter.shared.onResponseReceived { response in
                    NetworkToastManager.shared.updateWithResponse(response)
                }
            }
        }
        #endif
    }
    
}
