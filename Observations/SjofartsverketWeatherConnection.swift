//
//  SjofartsverketWeatherConnection.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-03.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import Foundation
import CoreLocation

enum SjofartsverketErrorType: ErrorType {
    case ConnectionError
    case NoStationWithMatchingId(id: Int)
}

struct Station {
    let id: Int
    let name: String
    let coordinate: CLLocationCoordinate2D
}

class SjofartsverketWeatherConnection: NSObject {
    
    var completionHandler:((Result<Weather>)->Void)!
    var stations: [Int: Station]
    private var gotStations = false
    
    override init() {
        self.stations = [Int: Station]()
        super.init()
        if let url = NSURL(string: "https://services.viva.sjofartsverket.se:8080/output/vivaoutputservice.svc/vivastation/") {
            let urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
            let task = urlSession.dataTaskWithURL(url, completionHandler: { (data, response, error) in
                guard let data = data else {
                    return
                }
                
                let result = JSON(data: data)
                guard let stations = result["GetStationsResult"]["Stations"].arrayObject else {
                    return
                }
                for stationDict in stations {
                    guard let id = stationDict["ID"] as? Int else { break }
                    guard let name = stationDict["Name"] as? String else { break }
                    guard let lat = stationDict["Lat"] as? Double else { break }
                    guard let lon = stationDict["Lon"] as? Double else { break }
                    
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    let station = Station(id: id, name: name, coordinate: coordinate)
                    self.stations[station.id] = station
                }
                self.gotStations = true
            })
            task.resume()
        }
    }
    
    func weatherAtLocationId(locationId: Int, completion: (Result<Weather>) -> Void) {
        completionHandler = completion
        
        if !gotStations {
            let runloop = NSRunLoop()
            var run = true
            while run {
                run = !gotStations
                runloop.runUntilDate(NSDate().dateByAddingTimeInterval(0.3))
            }
        }
                
        guard let station = stations[locationId] else {
            completion(Result.Error(e: SjofartsverketErrorType.NoStationWithMatchingId(id: locationId)))
            return
        }
        
        if let url = NSURL(string: "https://services.viva.sjofartsverket.se:8080/output/vivaoutputservice.svc/vivastation/\(locationId)") {
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "GET"
            
            let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let urlSession = NSURLSession(configuration: sessionConfiguration)
            let task = urlSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                guard let data = data else {
                    print(error)
                    self.completionHandler(Result.Error(e: error ?? SjofartsverketErrorType.ConnectionError))
                    self.completionHandler = nil
                    return
                }

                let result = JSON(data: data)
                let name = result["GetSingleStationResult"]["Name"].stringValue
                let samples = result["GetSingleStationResult"]["Samples"].arrayValue
                
                var averageWind: Double?
                var gustWind: Double?
                var heading: Double?
                var seaLevel: Double?
                var date: NSDate?
                
                for sample in samples {
                    let type = sample["Name"].stringValue
                    print(sample)
                    switch type {
                    case "Medelvind":
                        averageWind = Double(sample["Value"].stringValue.stripNonNumberCharacters()!)!
                        heading = Double(sample["Heading"].intValue) * Double(M_PI) / 180.0
                        date = self.parseVivaDate(sample["Updated"].stringValue)
                    case "Byvind":
                        gustWind = Double(sample["Value"].stringValue.stripNonNumberCharacters()!)!
                    case "Vattenstånd":
                        seaLevel = sample["Value"].doubleValue / 100.0
                    default:
                        break
                    }
                }
                
                let weather = Weather(locationName: name, coordinate: station.coordinate, windSpeed: averageWind!, windGusts: gustWind!, windDirection: heading!, seaLevel: seaLevel!, date: date!)
                
                completion(Result.Success(weather))
            })
            task.resume()
        }
    }
    
    private func parseVivaDate(dateString: String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 1 * 60 * 60)
        return dateFormatter.dateFromString(dateString)!
    }
}


extension Weather {
    
    init(locationName: String, coordinate: CLLocationCoordinate2D, windSpeed: Double, windGusts: Double, windDirection: Double, seaLevel: Double, date: NSDate) {
        self.provider = WeatherProvider.Sjofartsverket
        self.locationName = locationName
        self.coordinate = coordinate
        self.windSpeed = windSpeed
        self.windGusts = windGusts
        self.windDirection = windDirection
        self.seaLevel = seaLevel
        self.date = date
        
        self.stationHeight = nil
        self.temperature = nil
        self.humidity = nil
        self.pressure = nil
    }
}