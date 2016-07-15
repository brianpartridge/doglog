//
//  UIColor+Hex.swift
//  Dog Log
//
//  Created by Brian Partridge on 7/14/16.
//  Copyright © 2016 Pear Tree Labs. All rights reserved.
//

import UIKit

// Blatantly taken from: http://stackoverflow.com/a/19072934/4992155
extension UIColor {
    convenience init(hexString: String, alpha: CGFloat? = 1.0) {
        let hexint = Int(intFromHexString(hexString))
        let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
        let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
        let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
        let alpha = alpha!
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private func intFromHexString(hexStr: String) -> UInt32 {
    var hexInt: UInt32 = 0
    let scanner = NSScanner(string: hexStr)
    scanner.charactersToBeSkipped = NSCharacterSet(charactersInString: "#")
    scanner.scanHexInt(&hexInt)
    return hexInt
}

extension UIColor {
    static var icon: UIColor {
        return UIColor(hexString: "#1b93d4")
    }
}
