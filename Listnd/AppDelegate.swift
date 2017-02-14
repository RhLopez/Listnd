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
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        stack.saveContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        stack.saveContext()
    }
}

