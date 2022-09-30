//
//  DrawerScrollView.swift
//  UIComponents
//
//  Created by Denis Maltsev on 29.09.2022.
//

import Foundation
import UIKit

class DrawerScrollView: UIScrollView {

    var didChangeContentSize: ((_ size: CGSize) -> Void)?

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if let obj = object as? UIScrollView {
            if obj == self && keyPath == "contentSize" {
                didChangeContentSize?(obj.contentSize)
            }
        }
    }
}
