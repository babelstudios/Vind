//
//  SMHIObservationConnection.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-18.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import Foundation

enum SMHIResultType {
    case Success(r: Dictionary<String, Double>)
    case Error(e: ErrorType)
}


class SMHIObservationConnection: NSObject {
    
    var completionHandler:((SMHIResultType)->Void)!
    
    func weatherObservation(completion: (SMHIResultType) -> Void) {
        completionHandler = completion
        
        
        
        // List all stations: "http://opendata-download-metobs.smhi.se/api/version/latest/parameter/4.json"
        // Data from bromma: "http://opendata-download-metobs.smhi.se/api/version/latest/parameter/4/station/97200.json"
        
        if let url = NSURL(string: "http://opendata-download-metobs.smhi.se/api/version/latest/parameter/6/station/97200/period/latest-hour/data.json") {
            
            print("get data from \(url)")
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "GET"
            //            request.HTTPBody = soapMessage.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            
            let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let urlSession = NSURLSession(configuration: sessionConfiguration)
            let task = urlSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                guard let data = data else {
                    print(error)
                    self.completionHandler(SMHIResultType.Error(e: error!))
                    self.completionHandler = nil
                    return
                }
                print("Got data \(data)")
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
                
                
                completion(SMHIResultType.Success(r: ["hepp": 3.14]))
                
                //                print("Samples: \(samples)")
                
                //                print("JSON: \(result)")
            })
            task.resume()
        }
    }
}