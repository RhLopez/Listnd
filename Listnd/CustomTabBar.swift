//
//  CustomTabBar.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 3/7/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class CustomTabBar: UITabBarController {
    
    let yPosition = UIScreen.main.bounds.height - (49 + 76)
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tabBar.barTintColor = UIColor.darkGray
        self.tabBar.unselectedItemTintColor = UIColor.lightGray
        self.tabBar.tintColor = UIColor.white
        
        if SpotifyPlayer.isPlaying {
            let nowPlayingView = UIView(frame: CGRect(x: 0, y: yPosition, width: UIScreen.main.bounds.width, height: 76.0))
            nowPlayingView.backgroundColor = .red
            if let miniPlayer = Bundle.main.loadNibNamed("NowPlaying", owner: self, options: nil)?.first as? NowPlaying {
                nowPlayingView.addSubview(miniPlayer)
                self.view.addSubview(nowPlayingView) 
            }
        }
    }
}

/****************************
 create containter view
 add nowPlaying VIEWCONTROLLER to container
 ******************/

