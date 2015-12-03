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
    
    
    let vivaConnection = VivaObservationsConnection()
    var currentWindObservation: WindObservation?
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
        
        guard let current = currentWindObservation else {
            print("No current observation, lets update.")
            vivaConnection.windObservationAtLocationId(2, completion:{ (result: ResultType) -> Void in
                switch result {
                case .Success(let wind):
                    print("Initial update with data \(wind)")
                    self.currentWindObservation = wind
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
        if secondsToDate < 60 * 20 {
            components.hour = components.hour + 1
            date = calendar.dateFromComponents(components)!
        }
        
        print("Request update complication @ \(date). Curren time \(now)")
        print("========================================================")
        handler(date);
    }
    
    func requestedUpdateDidBegin() {
        print("requestedUpdateDidBegin @ \(NSDate())");
        
        vivaConnection.windObservationAtLocationId(2, completion:{ (result: ResultType) -> Void in
            switch result {
            case .Success(let wind):
                print("Succesfully updated with data \(wind)")
                self.currentWindObservation = wind
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
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        
        let fakeObservation = WindObservation(location: "Foobar", speed: 9.0, gusts: 10.0, direction: 3.0, date: NSDate())
        
        handler(templateForObservation(fakeObservation, complication: complication))
    }
    
    private func templateForObservation(observation: WindObservation, complication: CLKComplication) -> CLKComplicationTemplate? {
        
        let imageProvider = CLKImageProvider(onePieceImage: observation.arrowImage())
        
        let textProvider:CLKSimpleTextProvider
        if self.lastError != nil || observation.speed < 0 {
            textProvider = CLKSimpleTextProvider(text: "--")
        } else {
            let formatter = NSNumberFormatter()
            formatter.numberStyle = .DecimalStyle
            formatter.maximumSignificantDigits = 2
            formatter.usesSignificantDigits = true
            formatter.roundingMode = .RoundHalfUp
            let windSpeed = formatter.stringFromNumber(NSNumber(float: observation.speed))!
            textProvider = CLKSimpleTextProvider(text: "\(windSpeed) m/s")
        }
        
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
