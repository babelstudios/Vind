//
//  SMHIObservationConnection.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-18.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import Foundation
import CoreLocation

enum SMHIService: Int {
    case Temperature = 1
    case Humidity = 6
    case Pressure = 9
    case WindSpeed = 4
    case WindGusts = 21
    case WindDirection = 3
    
    //    static let allValues = [Temperature, Humidity, Pressure, WindSpeed, WindGusts, WindDirection]
    static let allValues = [Temperature, Humidity]
}

struct SMHIStation {
    let id: Int
    let name: String
    let height: Int
    let coordinate: CLLocationCoordinate2D
    var services:[SMHIService]
    
    init(id: Int, name: String, height: Int, coordinate: CLLocationCoordinate2D, services: [SMHIService]) {
        self.id = id
        self.name = name
        self.height = height
        self.coordinate = coordinate
        self.services = services
    }
    
    init(station: SMHIStation, services:[SMHIService]) {
        id = station.id
        name = station.name
        height = station.height
        coordinate = station.coordinate
        self.services = services
    }
}

class SMHIWeatherConnection: NSObject {
    
    var completionHandler: ((Result<Weather>)->Void)!
    var currentWeather: [SMHIService: Double]?
    var stations: [Int: SMHIStation]

    private var activeStationTasks = [NSURL]()
    
    override init() {
        stations = [Int: SMHIStation]()
        super.init()

        "http://opendata-download-metobs.smhi.se/api/version/latest/parameter/1/station/97200/period/latest-hour/data.json"

        for service in SMHIService.allValues {
            
            let url = NSURL(string: "http://opendata-download-metobs.smhi.se/api/version/latest/parameter/\(service.rawValue)/station-set/all/period/latest-hour/data.json")!
            
            print(url)
            let urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
            let task = urlSession.dataTaskWithURL(url, completionHandler: { (data, response, error) in
                guard let data = data else { return }
                let result = JSON(data: data)
                let stations = result["station"].arrayValue
                
                for station in stations {
                    guard let stringStationId = station["key"].string else {continue}
                    guard let stationId = Int(stringStationId) else {continue}
                    guard let name = station["name"].string else {continue}
                    guard let height = station["height"].int else {continue}
                    guard let lon = station["longitude"].double else {continue}
                    guard let lat = station["latitude"].double else {continue}
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        if self.stations[stationId] == nil {
                            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            self.stations[stationId] = SMHIStation(id: stationId, name: name, height: height, coordinate: coordinate, services: [SMHIService]())
                        }
                        self.stations[stationId]!.services.append(service)
                    })
                }
                
                self.activeStationTasks = self.activeStationTasks.filter({$0 != url})
                
                if self.activeStationTasks.count == 0 {
                    print("done parsing data")
                    //                    print(self.stations)
                }
            })
            activeStationTasks.append(url)
            task.resume()
        }
    }
    
    
    func weatherAtLocationId(stationId: Int, services: [SMHIService], completion: (Result<Weather>) -> Void) {
        completionHandler = completion
        currentWeather = [SMHIService: Double]()
        
        for service in services {
            
            let url = NSURL(string: "http://opendata-download-metobs.smhi.se/api/version/latest/parameter/\(service.rawValue)/station/\(stationId)/period/latest-hour/data.json")!
            print(url)
            let urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
            let task = urlSession.dataTaskWithURL(url, completionHandler: { (data, response, error) in
                guard let data = data else { return }
                let result = JSON(data: data)
                print(result)
            })
            task.resume()
        }
    }
    
    func weatherObservation(completion: (Result<Weather>) -> Void) {

        
        // List all stations: "http://opendata-download-metobs.smhi.se/api/version/latest/parameter/4.json"
        // Data from bromma: "http://opendata-download-metobs.smhi.se/api/version/latest/parameter/4/station/97200.json"
        
        if let url = NSURL(string: "http://opendata-download-metobs.smhi.se/api/version/latest/parameter/6/station/97200/period/latest-hour/data.json") {
            
            print("get data from \(url)")
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "GET"
            
            let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let urlSession = NSURLSession(configuration: sessionConfiguration)
            let task = urlSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                guard let data = data else {
                    print(error)
                    self.completionHandler(Result.Error(e: error!))
                    self.completionHandler = nil
                    return
                }
                let result = JSON(data: data)
                print(result)
                //                let name = result["GetSingleStationResult"]["Name"].stringValue
                //                let samples = result["GetSingleStationResult"]["Samples"].arrayValue
                //
                //                var averageWind:Double?
                //                var gustWind:Double?
                //                var heading:Double?
                //                var date:NSDate?
                
                //                for sample in samples {
                //                    let type = sample["Name"].stringValue
                //
                //                    switch type {
                //                    case "Medelvind":
                //                        print("Medelvind \(Double(sample["Value"].stringValue))")
                //                        averageWind = Double(sample["Value"].stringValue.stripNonNumberCharacters()!)!
                //                        heading = Double(sample["Heading"].intValue) * Double(M_PI) / 180.0
                //                        date = self.parseVivaDate(sample["Updated"].stringValue)!
                //                    case "Byvind":
                //                        print("Byvind \(Double(sample["Value"].stringValue))")
                //                        gustWind = Double(sample["Value"].stringValue.stripNonNumberCharacters()!)!
                //                    default:
                //                        print("not type")
                //                    }
                //
                //                }
                
                //                let observation = WindObservation(location: name, speed: averageWind!, gusts: gustWind!, direction: heading!, date: date!)
                
                
                
                
                //                completion(Result.Success(r: ["hepp": 3.14]))
                
                
                
                
                
                //                print("Samples: \(samples)")
                
                //                print("JSON: \(result)")
            })
            task.resume()
        }
    }
}