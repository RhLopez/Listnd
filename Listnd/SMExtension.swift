//
//  SMExtension.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 11/26/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit
import SwiftMessages

extension SwiftMessages {
    func displayConfirmation(message: String) {
        let view = MessageView.viewFromNib(layout: .StatusLine)
        view.configureTheme(.success)
        view.configureDropShadow()
        view.configureContent(body: message)
        view.configureTheme(backgroundColor: UIColor(red: 236/255, green: 115/255, blue: 49/255, alpha: 1), foregroundColor: UIColor.white)
        var config = SwiftMessages.Config()
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = .seconds(seconds: 0.5)
        SwiftMessages.show(config: config, view: view)
    }
    
    func displayError(title: String, message: String) {
        let view = MessageView.viewFromNib(layout: .MessageView)
        view.configureTheme(.error)
        view.configureContent(title: title, body: message)
        view.button?.isHidden = true
        var config = SwiftMessages.Config()
        config.duration = .forever
        config.dimMode = .gray(interactive: true)
        SwiftMessages.show(config: config, view: view)
    }
    
    func displayCustomMessage() {
        let view: CustomDialogView = try! SwiftMessages.viewFromNib(named: "CustomMessage")
        var config = SwiftMessages.Config()
        config.duration = .forever
        config.dimMode = .gray(interactive: false)
        SwiftMessages.show(config: config, view: view)
    }
}
