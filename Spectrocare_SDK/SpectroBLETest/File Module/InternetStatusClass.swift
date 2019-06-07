//
//  InternetStatusClass.swift
//  Impulse8050
//
//  Created by VedsAshk on 28/09/16.
//  Copyright © 2016 Holux. All rights reserved.
//

import UIKit
import SystemConfiguration
import Foundation


let wiFiStatusIdentifier: String = "wiFiStatusIdentifier"
let wifiStatusNotification  =  Notification.Name(rawValue: wiFiStatusIdentifier)

class InternetStatusClass: NSObject{
    var reachability:Reachability!
    var isConnected = true
    
    class var sharedInstance : InternetStatusClass{
        struct Singleton{
            static let instance = InternetStatusClass()
        }
        return Singleton.instance
    }
    
    private override init(){
        super.init()
        reachability = Reachability(hostname: "www.google.com")
        reachabilityChanged()
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged), name: ReachabilityChangedNotification, object: reachability)
        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
    }
    
    @objc func reachabilityChanged() {
        
        if reachability.currentReachabilityStatus == .notReachable{
            isConnected = false
        }
        else{
            isConnected = true
        }
        NotificationCenter.default.post(Notification.init(name: wifiStatusNotification))
    }

    
    
    
}
