//
//  AlertView.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 11/21/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class AlerView: NSObject {
    
    class func showAlert(view: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            DispatchQueue.main.async {
                view.present(alert, animated: true, completion: nil)
        }
    }
}
