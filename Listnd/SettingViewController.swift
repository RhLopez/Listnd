//
//  SettingViewController.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 2/25/17.
//  Copyright © 2017 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import SafariServices

// MARK: - NotifcationKey
let loginSuccessfullNotification = "com.RhL.loginSuccessfull"

class SettingViewController: UIViewController {
    
    var authController: SFSafariViewController!
    @IBOutlet weak var logInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let userDefaults = UserDefaults()
        let premiumSubscriber = userDefaults.bool(forKey: "PremiumUser")
        if premiumSubscriber {
            logInButton.setTitle("LOG OUT FROM SPOTIFY", for: .normal)
        }
        logInButton.layer.cornerRadius = 14
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateAfterLogin),
                                               name: Notification.Name(rawValue: loginSuccessfullNotification),
                                               object: nil)
    }
    
    @IBAction func logInButtonPressed(_ sender: Any) {
        let auth = SPTAuth.defaultInstance()
        auth?.clientID = "8faa83925ca64e5997e01122da55dcf0"
        auth?.redirectURL = URL(string: "listnd://returnAfterLogin")
        auth?.sessionUserDefaultsKey = "current session"
        auth?.requestedScopes = [SPTAuthStreamingScope]
        auth?.tokenSwapURL = URL(string: "https://pacific-spire-64693.herokuapp.com/swap")
        let loginURL = auth?.spotifyWebAuthenticationURL()
        authController = SFSafariViewController(url: loginURL!)
        present(authController, animated: true, completion: nil)
    }
    
    func updateAfterLogin() {
        authController.presentingViewController?.dismiss(animated: true, completion: nil)
        logInButton.setTitle("LOG OUT FROM SPOTIFY", for: .normal)
    }
    
    @IBAction func exitButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
