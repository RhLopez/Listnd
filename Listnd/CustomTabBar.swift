//
//  CustomTabBar.swift
//  Listnd
//
//  Created by Ramiro H Lopez on 4/14/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class CustomTabBar: UITabBarController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBar.barTintColor = UIColor(red: 0.412, green: 0.443, blue: 0.486, alpha: 1.00)
        self.tabBar.unselectedItemTintColor = .lightGray
        self.tabBar.tintColor = .white
    }
}
