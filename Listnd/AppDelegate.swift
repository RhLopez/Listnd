//
//  AppDelegate.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    lazy var coreDataStack = CoreDataStack(modelName: "Model")
    let stack = CoreDataStack.sharedInstance
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        guard let tabController = window?.rootViewController as? UITabBarController,
            let firstNavController = tabController.viewControllers?[0] as? UINavigationController,
            let firstTabController = firstNavController.topViewController as? FavoriteArtistTableViewController,
            let secondNavController = tabController.viewControllers?[1] as? UINavigationController,
            let secondTabController = secondNavController.topViewController as? SearchViewController else {
                return true
        }

        firstTabController.coreDataStack = coreDataStack
        secondTabController.coreDataStack = coreDataStack
        
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        stack.saveContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        stack.saveContext()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if SPTAuth.defaultInstance().canHandle(url) {
            SPTAuth.defaultInstance().handleAuthCallback(withTriggeredAuthURL: url, callback: { (error, session) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                let userDefaults = UserDefaults()
                let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!) as NSData
                userDefaults.set(sessionData, forKey: "SpotifySession")
                userDefaults.set(true, forKey: "PremiumUser")
                userDefaults.synchronize()
                NotificationCenter.default.post(name: Notification.Name(rawValue: loginSuccessfullNotification), object: self)
            })
        }
        return false
    }
}

