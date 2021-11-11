//
//  UIApplicationActiveWindow.swift
//  fileMusic
//
//  Created by viewdidload on 2021/11/12.
//  Copyright © 2021 viewdidload soft. All rights reserved.
//

import UIKit

extension UIApplication {
    
    var activeWindow: UIWindow? {
        let activeWindows = connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
        
        if let keyWindow = activeWindows?.first(where: { $0.isKeyWindow }) {
            return keyWindow
        } else {
            return activeWindows?.first
        }
    }
    
    var topMostViewController: UIViewController? {
        guard let rootViewController = activeWindow?.rootViewController else {
            return nil
        }
        
        return topMostViewController(for: rootViewController)
    }
    
    private func topMostViewController(for viewController: UIViewController) -> UIViewController {
        if let presentedController = viewController.presentedViewController {
            return topMostViewController(for: presentedController)
        } else if let navigationController = viewController as? UINavigationController {
            guard let topViewController = navigationController.topViewController else {
                return navigationController
            }
            
            return topMostViewController(for: topViewController)
        } else if let tabBarController = viewController as? UITabBarController {
            guard let selectedViewController = tabBarController.selectedViewController else {
                return tabBarController
            }
            
            return topMostViewController(for: selectedViewController)
        }
        
        return viewController
    }
}
