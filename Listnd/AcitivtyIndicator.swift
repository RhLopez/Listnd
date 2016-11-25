//
//  AcitivtyIndicator.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 11/20/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import UIKit

class ActivityIndicator: NSObject {
    
    static let sharedInstance = ActivityIndicator()
    
    var indicatorView = UIView()
    
    func showSearchingIndicator(tableView: UIView, view: UIView) {
        indicatorView = UIView(frame: tableView.frame)
//        indicatorView.backgroundColor = UIColor.blue
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicatorView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        view.addSubview(indicatorView)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        indicatorView.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        indicatorView.bottomAnchor.constraint(equalTo: tableView.bottomAnchor).isActive = true
    }
    
    func hideSearchingIndicator() {
        indicatorView.removeFromSuperview()
    }
}
