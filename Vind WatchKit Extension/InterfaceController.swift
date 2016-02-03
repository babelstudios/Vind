//
//  InterfaceController.swift
//  Vind WatchKit Extension
//
//  Created by Jens Utbult on 2015-12-03.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var windArrowImage: WKInterfaceImage!
    @IBOutlet var windSpeedLabel: WKInterfaceLabel!
    @IBOutlet var waterLevelLabel: WKInterfaceLabel!
    
    let sjofartsverketConnection = SjofartsverketWeatherConnection()
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        getData()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func getData() {
        sjofartsverketConnection.weatherAtLocationId(2, completion:{ (result: Result) -> Void in
            switch result {
            case .Success(let weather):
                self.titleLabel.setText(weather.locationName)
                
                let formatter = NSNumberFormatter()
                formatter.numberStyle = .DecimalStyle
                formatter.maximumSignificantDigits = 2
                formatter.usesSignificantDigits = true
                formatter.roundingMode = .RoundHalfUp
                let windSpeed = formatter.stringFromNumber(NSNumber(double: weather.windSpeed!))!
                self.windSpeedLabel.setText("\(windSpeed) m/s")
                let image = UIImage.imageArrowForDirection(weather.windDirection!, size: CGSizeMake(30, 30), scale:0.65).imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                self.windArrowImage.setImage(image)
                self.waterLevelLabel.setText("\(Int(weather.seaLevel! * 100)) cm")
            case .Error(let e):
                print("Initial update failed with error: \(e)")
            }
        })
    }
}
