//
//  UIImage+Utilities.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-22.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    class func imageArrowForDirection(direction: Double) -> UIImage {
        return imageArrowForDirection(direction, color: UIColor.blackColor())
    }
    
    class func imageArrowForDirection(direction: Double, color: UIColor) -> UIImage {
        let size = CGSizeMake(30, 30)
        let arrowSize = CGSizeMake(15, 25)
        
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(arrowSize.width / 2, arrowSize.height))
        path.addLineToPoint(CGPointMake(arrowSize.width, 0))
        path.addLineToPoint(CGPointMake(arrowSize.width / 2, arrowSize.height * 0.15))
        path.addLineToPoint(CGPointMake(0, 0))
        
        path.lineJoinStyle = CGLineJoin.Miter
        path.closePath()
        
        let transform = CGAffineTransformTranslate(CGAffineTransformRotate(CGAffineTransformMakeTranslation(size.width / 2, size.height / 2), CGFloat(direction)), -arrowSize.width / 2, -arrowSize.height / 2)
        path.applyTransform(transform)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
        let fillColor = color
        fillColor.setFill()
        path.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
    }
}
