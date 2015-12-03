//
//  WindObservation.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-03.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import Foundation
import UIKit

struct WindObservation: CustomStringConvertible {
    var location: String
    var speed: Float
    var gusts: Float
    var direction: Float
    let date: NSDate
    
    init(location: String, speed: Float, gusts: Float, direction: Float, date: NSDate) {
        self.location = location
        self.speed = speed
        self.gusts = gusts
        self.direction = direction
        self.date = date
    }
    
    init(date: NSDate) {
        self.date = date
        self.location = ""
        self.direction = 0
        self.speed = 0
        self.gusts = 0
    }
    
    var description : String {
        return "\(location) (\(date)): speed=\(speed)m/s gusts=\(gusts) direction=\(direction)°"
    }
}

extension WindObservation {
    func arrowImage() -> UIImage {
        return arrowImageWithColor(UIColor.blackColor())
    }
    
    func arrowImageWithColor(color: UIColor) -> UIImage {
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