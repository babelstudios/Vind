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
    var speed: Double
    var gusts: Double
    var direction: Double
    let date: NSDate
    
    init(location: String, speed: Double, gusts: Double, direction: Double, date: NSDate) {
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
