//
//  SMExtension.swift
//  
//
//  Created by Ramiro H Lopez on 5/9/17.
//
//

import UIKit
import SwiftMessages

extension SwiftMessages {
    func displayConfirmation(message: String) {
        let view = MessageView.viewFromNib(layout: .StatusLine)
        view.configureTheme(.success)
        view.configureDropShadow()
        view.configureContent(body: message)
        view.configureTheme(backgroundColor: UIColor(red: 30/255, green: 200/255, blue: 80/255, alpha: 1), foregroundColor: UIColor.white)
        var config = SwiftMessages.Config()
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        config.duration = .seconds(seconds: 0.8)
        SwiftMessages.show(config: config, view: view)
    }
    
    func displayError(title: String, message: String) {
        let view = MessageView.viewFromNib(layout: .CardView)
        view.configureTheme(.error)
        view.configureContent(title: title, body: message)
        view.button?.isHidden = true
        view.tapHandler = { _ in SwiftMessages.hide() }
        var config = SwiftMessages.Config()
        config.duration = .seconds(seconds: 1.0)
        config.dimMode = .gray(interactive: true)
        SwiftMessages.show(config: config, view: view)
    } 
}
