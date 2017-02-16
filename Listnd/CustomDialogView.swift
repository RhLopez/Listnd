//
//  CustomDialogView.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 12/11/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit


class CustomDialogView: MessageView {
    var openAppStore: (() -> Void)?
    var cancelAction: (() -> Void)?
    
    @IBAction func openAppStore(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://appsto.re/us/KSKwt.i")!, options: [:], completionHandler: nil)
        SwiftMessages.hide()
    }
    @IBAction func cancelButtonPressed(_ sender: Any) {
        SwiftMessages.hide()
    }
}
