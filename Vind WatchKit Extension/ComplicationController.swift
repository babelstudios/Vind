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
    var weatherObservations = [Weather]()
    var lastError: ErrorType?
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Backward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        guard let oldestWeather = weatherObservations.first else {
            handler(nil)
            return
        }
        return handler(oldestWeather.date)
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        guard let currentWeather = weatherObservations.last else {
            handler(nil)
            return
        }
        handler(currentWeather.date)
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        
        guard let current = weatherObservations.last else {
            updateWeatherObservation()
            return
        }
        
        guard let complication = templateForObservation(current, complication: complication) else { return }
        let entry = CLKComplicationTimelineEntry(date: current.date, complicationTemplate:complication)
        handler(entry)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        
        let entries:[CLKComplicationTimelineEntry] = weatherObservations.filter { weather in
            return weather.date.compare(date) == .OrderedAscending
            }.flatMap { weather in
                guard let complication = templateForObservation(weather, complication: complication) else { return nil }
                return CLKComplicationTimelineEntry(date: weather.date, complicationTemplate:complication)
        }
        
        handler(entries)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {

        // Make sure all updates happen on an even quarter of an hour
        let now = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Era, .Year, .Month, .Day, .Hour, .Minute], fromDate: now)
        components.minute += 15 - components.minute % 15
        let date = calendar.dateFromComponents(components)!
//        let secondsToDate = date.timeIntervalSinceNow
//        if secondsToDate < 60 * 10 {
//            components.hour = components.hour + 1
//            date = calendar.dateFromComponents(components)!
//        }
        
        print("Request update complication @ \(date). Curren time \(now)")
        print("========================================================")
        handler(date);
    }
    
    func updateWeatherObservation() {
        
        sjofartsverketConnection.weatherAtLocationId(2, completion:{ (result: Result) -> Void in
            switch result {
            case .Success(let weather):
                if let current = self.weatherObservations.last {
                    if current.date.compare(weather.date) != .OrderedSame {
                        if self.weatherObservations.count > 95 {
                            self.weatherObservations.removeFirst()
                        }
                        self.weatherObservations.append(weather)
                    }
                } else {
                    self.weatherObservations.append(weather)
                }
                self.lastError = nil
                let server = CLKComplicationServer.sharedInstance()
                for complication in server.activeComplications! {
                    server.reloadTimelineForComplication(complication)
                }
            case .Error(let e):
                self.lastError = e
                print("Failed updating with error: \(e)")
            }
        })
    }
    
    func requestedUpdateDidBegin() {
        print("requestedUpdateDidBegin @ \(NSDate())");
        updateWeatherObservation()
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
