//
//  ComplicationController.swift
//  Vind WatchKit Extension
//
//  Created by Jens Utbult on 2015-12-03.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    let sjofartsverketConnection = SjofartsverketWeatherConnection()
    var currentWeather: Weather?
    var lastError: ErrorType?
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Forward, .Backward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        
        guard let current = currentWeather else {
            print("No current observation, lets update.")
            sjofartsverketConnection.weatherAtLocationId(2, completion:{ (result: Result) -> Void in
                switch result {
                case .Success(let wind):
                    print("Initial update with data \(wind)")
                    self.currentWeather = wind
                    let server = CLKComplicationServer.sharedInstance()
                    for complication in server.activeComplications {
                        server.reloadTimelineForComplication(complication)
                    }
                case .Error(let e):
                    print("Initial update failed with error: \(e)")
                }
            })
            handler(nil)
            return
        }
        
        guard let complication = templateForObservation(current, complication: complication) else {
            handler(nil)
            return
        }
        
        let entry = CLKComplicationTimelineEntry(date: current.date, complicationTemplate:complication)
        handler(entry)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        let now = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Era, .Year, .Month, .Day, .Hour], fromDate: now)
        components.hour = components.hour + 1
        var date = calendar.dateFromComponents(components)!
        let secondsToDate = date.timeIntervalSinceNow
        if secondsToDate < 60 * 10 {
            components.hour = components.hour + 1
            date = calendar.dateFromComponents(components)!
        }
        
        print("Request update complication @ \(date). Curren time \(now)")
        print("========================================================")
        handler(date);
    }
    
    func requestedUpdateDidBegin() {
        print("requestedUpdateDidBegin @ \(NSDate())");
        
        sjofartsverketConnection.weatherAtLocationId(2, completion:{ (result: Result) -> Void in
            switch result {
            case .Success(let weather):
                print("Succesfully updated with data \(weather)")
                self.currentWeather = weather
                self.lastError = nil
                let server = CLKComplicationServer.sharedInstance()
                for complication in server.activeComplications {
                    server.reloadTimelineForComplication(complication)
                }
            case .Error(let e):
                self.lastError = e
                print("Failed updating with error: \(e)")
            }
        })
    }
    
    func requestedUpdateBudgetExhausted() {
        print("requestedUpdateBudgetExhausted @ \(NSDate())")
    }
    
    // MARK: - Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        handler(templateForObservation(nil, complication: complication))
    }
    
    private func templateForObservation(observation: Weather?, complication: CLKComplication) -> CLKComplicationTemplate? {

        let textProvider:CLKSimpleTextProvider
        let image:UIImage
        
        if let observation = observation {
            let formatter = NSNumberFormatter()
            formatter.numberStyle = .DecimalStyle
            formatter.maximumSignificantDigits = 2
            formatter.usesSignificantDigits = true
            formatter.roundingMode = .RoundHalfUp
            let windSpeed = formatter.stringFromNumber(NSNumber(double: observation.windSpeed!))!
            textProvider = CLKSimpleTextProvider(text: "\(windSpeed) m/s")
            image = UIImage.imageArrowForDirection(observation.windDirection!)
        } else {
            textProvider = CLKSimpleTextProvider(text: "-- m/s")
            image = UIImage.imageArrowForDirection(0.5)
        }
        
        let imageProvider = CLKImageProvider(onePieceImage: image)
        
        //        let dateFormatter = NSDateFormatter()
        //        dateFormatter.dateFormat = "HH:mm"
        //        let textProvider = CLKSimpleTextProvider(text: dateFormatter.stringFromDate(NSDate()))
        
        let template: CLKComplicationTemplate?
        switch complication.family {
        case .ModularSmall:
            template = CLKComplicationTemplateModularSmallStackImage()
            if let template = template as? CLKComplicationTemplateModularSmallStackImage {
                template.line1ImageProvider = imageProvider
                template.line2TextProvider = textProvider
            }
        default:
            template = nil
        }
        
        return template;
    }
    
}
