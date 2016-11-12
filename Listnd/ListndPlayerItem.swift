//
//  ListndPlayerItem.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/29/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import AVFoundation

protocol ListndPlayerItemDelegate: class {
    func playerReady()
}

class ListndPlayerItem: AVPlayerItem {
    
    weak var delegate: ListndPlayerItemDelegate?
    
    init(url: URL) {
        super.init(asset: AVAsset(url: url), automaticallyLoadedAssetKeys: [])
        self.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: .new, context: nil)
    }
    
    deinit {
        self.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            if self.status == AVPlayerItemStatus.readyToPlay {
                delegate?.playerReady()
            }
        }
    }
}
