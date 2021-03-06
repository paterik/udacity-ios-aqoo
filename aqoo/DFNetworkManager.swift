//
//  DFNetworkManager.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 12.12.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//  inspired by https://blog.pusher.com/handling-internet-connection-reachability-swift/
//

import Foundation
import Reachability

class DFNetworkManager: NSObject {
    
    //
    // MARK: Class Constants (Statics)
    //
    
    static let sharedInstance: DFNetworkManager = { return DFNetworkManager() }()
    
    //
    // MARK: Class Constants (Normal)
    //
    
    let debugMode: Bool = true
    
    //
    // MARK: Class Variables
    //
    
    var reachability: Reachability!
    
    //
    // MARK: Class Initializer
    //
    
    override init() {
        
        super.init()
        
        // Initialise reachability
        reachability = Reachability()!
        
        // Register an observer for the network status
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged(_:)),
            name: .reachabilityChanged,
            object: reachability
        )
        
        do {
            // Start the network status notifier
            try reachability.startNotifier()
        }   catch {
            if  debugMode {
                print ("dbg [DFNetworkManager] : Unable to start notifier")
            }
        }
    }
    
    //
    // MARK: Class Methods (mixed)
    //
    
    @objc func networkStatusChanged(_ notification: Notification) {
        
        if  debugMode {
            print ("dbg [DFNetworkManager] : network status changed!")
        }
    }
    
    static func stopNotifier() -> Void {
        
        do {
            // Stop the network status notifier
            try (DFNetworkManager.sharedInstance.reachability).startNotifier()
        }   catch {
            print ("dbg [DFNetworkManager] : Unable to stop notifier")
        }
    }
    
    // Network is reachable
    static func isReachable(completed: @escaping (DFNetworkManager) -> Void) {
        
        if (DFNetworkManager.sharedInstance.reachability).connection != .none {
            completed(DFNetworkManager.sharedInstance)
        }
    }
    
    // Network is unreachable
    static func isUnreachable(completed: @escaping (DFNetworkManager) -> Void) {
        
        if (DFNetworkManager.sharedInstance.reachability).connection == .none {
            completed(DFNetworkManager.sharedInstance)
        }
    }
    
    // Network is reachable via WWAN/Cellular
    static func isReachableViaWWAN(completed: @escaping (DFNetworkManager) -> Void) {
        
        if (DFNetworkManager.sharedInstance.reachability).connection == .cellular {
            completed(DFNetworkManager.sharedInstance)
        }
    }
    
    // Network is reachable via WiFi
    static func isReachableViaWiFi(completed: @escaping (DFNetworkManager) -> Void) {
        
        if (DFNetworkManager.sharedInstance.reachability).connection == .wifi {
            completed(DFNetworkManager.sharedInstance)
        }
    }
}
